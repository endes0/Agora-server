//Under GNU AGPL v3, see LICENCE

package beartek.agora.server.commands;

import beartek.agora.types.Protocol_types;
import beartek.agora.types.Tid;

class Db {

  public function new() {
    Main.handlers.commands.register_handler('db_add', this.db_add);

  }

  public function db_add( cmd : Array<String> ) : Bool {
    if(cmd.length < 2) throw 'Insufficient arguments.';

    switch cmd[1] {
    case 'loginkey':
      var key : String = haxe.Serializer.run(Main.handlers.sessions.generate_loginkey(cmd[2], cmd[3]));
      var id : Tid = Tid.fromString(cmd[4]);

      Main.db.loginkey.create(key, id.toString());
    case _:
      trace( 'Subcommand not found.' );
      return false;
    }
    //TODO: anadir mas subcomandos

    return true;
  }


}
