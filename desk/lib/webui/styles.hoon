|%
++  global
  ^~
  ^-  tape
  %-  trip
  '''
  * { margin: 0.2em; padding: 0.01em; font-family: monospace; }
  body {
    margin: 0;
    padding: 0;
    font-size: large;
    width: 100vw;
    display: flex;
    flex-direction: column;
  }
  input, select, textarea, button, label {font-size: large}
  table {
    font-size: large;
  }
  .box {
    border: 1px black;
    width: fit-content;
    border-style: solid;
  }
  .justified-form {
    display: flex;
    flex-direction: row;
    justify-content: space-between;
  }
  .ok { color: #070; }
  .bad { color: #b00; }
  .errors, .warnings {
    max-width: 80ch;
    padding: 0.5em;
    border: 2px solid;
  }
  .errors { border-color: #b00; }
  .warnings { border-color: #c80; }
  summary { cursor: pointer; }
  '''
--
