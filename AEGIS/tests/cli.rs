use std::process::Command;

#[test]
fn version_command_matches_package_version() {
    let output = Command::new(env!("CARGO_BIN_EXE_aegis"))
        .arg("version")
        .output()
        .unwrap();
    assert!(output.status.success());
    assert_eq!(String::from_utf8(output.stdout).unwrap().trim(), "0.1.0");
}
