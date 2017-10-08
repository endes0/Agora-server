//Under GNU AGPL v3, see LICENCE

package beartek.agora.server.commands;


class Core {

  public function new() {
    Main.handlers.commands.register_handler('exit', this.exit);
    Main.handlers.commands.register_handler('help', this.help);

  }

  public function exit( cmd : Array<String> ) : Bool {
    trace( 'Exiting ...' );
    Main.off();
    return true;
  }

  public function help( cmd : Array<String> ) : Bool {
    trace( 'Commands: ' );

    var cmds : Array<String> = Main.handlers.commands.list();
    trace( cmds.toString() );
    return true;
  }

}
