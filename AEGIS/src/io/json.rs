use std::collections::BTreeMap;

use crate::error::AegisError;

#[derive(Debug, Clone, PartialEq)]
pub enum JsonValue {
    Null,
    Bool(bool),
    Number(f64),
    String(String),
    Array(Vec<JsonValue>),
    Object(BTreeMap<String, JsonValue>),
}

pub fn parse(text: &str) -> Result<JsonValue, AegisError> {
    let mut parser = Parser::new(text);
    let value = parser.parse_value()?;
    parser.skip_ws();
    if !parser.is_end() {
        return Err(parser.error("unexpected trailing content"));
    }
    Ok(value)
}

struct Parser<'a> {
    bytes: &'a [u8],
    pos: usize,
}

impl<'a> Parser<'a> {
    fn new(text: &'a str) -> Self {
        Self {
            bytes: text.as_bytes(),
            pos: 0,
        }
    }

    fn is_end(&self) -> bool {
        self.pos >= self.bytes.len()
    }

    fn skip_ws(&mut self) {
        while matches!(self.peek(), Some(b' ' | b'\t' | b'\r' | b'\n')) {
            self.pos += 1;
        }
    }

    fn parse_value(&mut self) -> Result<JsonValue, AegisError> {
        self.skip_ws();
        let byte = self.peek().ok_or_else(|| self.error("unexpected end of JSON"))?;
        match byte {
            b'{' => self.parse_object(),
            b'[' => self.parse_array(),
            b'"' => self.parse_string().map(JsonValue::String),
            b't' => {
                self.expect_bytes(b"true")?;
                Ok(JsonValue::Bool(true))
            }
            b'f' => {
                self.expect_bytes(b"false")?;
                Ok(JsonValue::Bool(false))
            }
            b'n' => {
                self.expect_bytes(b"null")?;
                Ok(JsonValue::Null)
            }
            b'-' | b'0'..=b'9' => self.parse_number().map(JsonValue::Number),
            _ => Err(self.error("unexpected JSON token")),
        }
    }

    fn parse_object(&mut self) -> Result<JsonValue, AegisError> {
        self.consume(b'{')?;
        self.skip_ws();
        let mut object = BTreeMap::new();
        if self.peek() == Some(b'}') {
            self.pos += 1;
            return Ok(JsonValue::Object(object));
        }
        loop {
            self.skip_ws();
            let key = self.parse_string()?;
            self.skip_ws();
            self.consume(b':')?;
            let value = self.parse_value()?;
            object.insert(key, value);
            self.skip_ws();
            match self.peek() {
                Some(b',') => self.pos += 1,
                Some(b'}') => {
                    self.pos += 1;
                    break;
                }
                _ => return Err(self.error("expected ',' or '}' in object")),
            }
        }
        Ok(JsonValue::Object(object))
    }

    fn parse_array(&mut self) -> Result<JsonValue, AegisError> {
        self.consume(b'[')?;
        self.skip_ws();
        let mut array = Vec::new();
        if self.peek() == Some(b']') {
            self.pos += 1;
            return Ok(JsonValue::Array(array));
        }
        loop {
            array.push(self.parse_value()?);
            self.skip_ws();
            match self.peek() {
                Some(b',') => self.pos += 1,
                Some(b']') => {
                    self.pos += 1;
                    break;
                }
                _ => return Err(self.error("expected ',' or ']' in array")),
            }
        }
        Ok(JsonValue::Array(array))
    }

    fn parse_string(&mut self) -> Result<String, AegisError> {
        self.consume(b'"')?;
        let mut output = String::new();
        while let Some(byte) = self.peek() {
            self.pos += 1;
            match byte {
                b'"' => return Ok(output),
                b'\\' => {
                    let escaped = self.peek().ok_or_else(|| self.error("incomplete escape"))?;
                    self.pos += 1;
                    match escaped {
                        b'"' => output.push('"'),
                        b'\\' => output.push('\\'),
                        b'/' => output.push('/'),
                        b'b' => output.push('\u{0008}'),
                        b'f' => output.push('\u{000C}'),
                        b'n' => output.push('\n'),
                        b'r' => output.push('\r'),
                        b't' => output.push('\t'),
                        b'u' => {
                            let first = self.parse_hex4()?;
                            let code = if (0xD800..=0xDBFF).contains(&first) {
                                self.expect_bytes(b"\\u")?;
                                let second = self.parse_hex4()?;
                                if !(0xDC00..=0xDFFF).contains(&second) {
                                    return Err(self.error("invalid Unicode surrogate pair"));
                                }
                                0x10000 + ((first as u32 - 0xD800) << 10)
                                    + (second as u32 - 0xDC00)
                            } else {
                                first as u32
                            };
                            let ch = char::from_u32(code)
                                .ok_or_else(|| self.error("invalid Unicode escape"))?;
                            output.push(ch);
                        }
                        _ => return Err(self.error("unsupported JSON escape")),
                    }
                }
                b if b < 0x20 => return Err(self.error("control character in JSON string")),
                b if b < 0x80 => output.push(b as char),
                _ => {
                    // Decode the complete UTF-8 scalar starting at the current byte.
                    self.pos -= 1;
                    let remaining = std::str::from_utf8(&self.bytes[self.pos..])
                        .map_err(|_| self.error("invalid UTF-8 in JSON string"))?;
                    let ch = remaining
                        .chars()
                        .next()
                        .ok_or_else(|| self.error("invalid UTF-8 in JSON string"))?;
                    output.push(ch);
                    self.pos += ch.len_utf8();
                }
            }
        }
        Err(self.error("unterminated JSON string"))
    }

    fn parse_hex4(&mut self) -> Result<u16, AegisError> {
        if self.pos + 4 > self.bytes.len() {
            return Err(self.error("incomplete Unicode escape"));
        }
        let text = std::str::from_utf8(&self.bytes[self.pos..self.pos + 4])
            .map_err(|_| self.error("invalid Unicode escape"))?;
        self.pos += 4;
        u16::from_str_radix(text, 16).map_err(|_| self.error("invalid Unicode escape"))
    }

    fn parse_number(&mut self) -> Result<f64, AegisError> {
        let start = self.pos;
        if self.peek() == Some(b'-') {
            self.pos += 1;
        }
        match self.peek() {
            Some(b'0') => {
                self.pos += 1;
                if matches!(self.peek(), Some(b'0'..=b'9')) {
                    return Err(self.error("leading zero in JSON number"));
                }
            }
            Some(b'1'..=b'9') => self.consume_digits(),
            _ => return Err(self.error("expected integer digits")),
        }
        if self.peek() == Some(b'.') {
            self.pos += 1;
            let before = self.pos;
            self.consume_digits();
            if self.pos == before {
                return Err(self.error("expected digits after decimal point"));
            }
        }
        if matches!(self.peek(), Some(b'e') | Some(b'E')) {
            self.pos += 1;
            if matches!(self.peek(), Some(b'+') | Some(b'-')) {
                self.pos += 1;
            }
            let before = self.pos;
            self.consume_digits();
            if self.pos == before {
                return Err(self.error("expected exponent digits"));
            }
        }
        let text = std::str::from_utf8(&self.bytes[start..self.pos])
            .map_err(|_| self.error("invalid number"))?;
        let value = text
            .parse::<f64>()
            .map_err(|_| self.error("invalid JSON number"))?;
        if !value.is_finite() {
            return Err(self.error("JSON number must be finite"));
        }
        Ok(value)
    }

    fn consume_digits(&mut self) {
        while matches!(self.peek(), Some(b'0'..=b'9')) {
            self.pos += 1;
        }
    }

    fn expect_bytes(&mut self, expected: &[u8]) -> Result<(), AegisError> {
        if self.bytes.get(self.pos..self.pos + expected.len()) == Some(expected) {
            self.pos += expected.len();
            Ok(())
        } else {
            Err(self.error("unexpected literal"))
        }
    }

    fn consume(&mut self, expected: u8) -> Result<(), AegisError> {
        if self.peek() == Some(expected) {
            self.pos += 1;
            Ok(())
        } else {
            Err(self.error(&format!("expected '{}'", expected as char)))
        }
    }

    fn peek(&self) -> Option<u8> {
        self.bytes.get(self.pos).copied()
    }

    fn error(&self, message: &str) -> AegisError {
        AegisError::Parse(format!("{message} at byte {}", self.pos))
    }
}

pub fn escape_string(value: &str) -> String {
    let mut out = String::with_capacity(value.len() + 2);
    out.push('"');
    for ch in value.chars() {
        match ch {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            c if c < '\u{20}' => out.push_str(&format!("\\u{:04x}", c as u32)),
            c => out.push(c),
        }
    }
    out.push('"');
    out
}
