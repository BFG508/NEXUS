// app/www/js/custom_scripts.js
// Client-side interactivity for the G.A.I.A. Frontend

$(document).ready(function() {
    // Print a stylized diagnostic boot sequence to the browser console
    console.log(
        "%c G.A.I.A. Systems Online ",
        "background: #1f2833; color: #66fcf1; font-size: 16px; font-weight: bold; border: 1px solid #45a29e; border-radius: 3px;"
    );
    console.log("%c[SYSTEM]%c Astrobiology Engine: ACTIVE", "color: #45a29e;", "color: #c5c6c7;");
    console.log("%c[SYSTEM]%c Telemetry Link: STABLE", "color: #45a29e;", "color: #c5c6c7;");
    console.log("%c[SYSTEM]%c Awaiting orbital parameters...", "color: #45a29e;", "color: #c5c6c7;");
});
