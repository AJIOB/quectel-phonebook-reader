# Quectel Phone Book Reader

Read SIM Phone Book from Quectel M66 over serial port with AT commands.

Arguments:
* Serial port file descriptor (`/dev/ttyUSB0`, for example)
* Serial port baudrate (`9600`, for example)
* Current working mode:
    * `read`: read modem contact book to file & create write commands
    * `write`: write modem contact book from file to SIM
