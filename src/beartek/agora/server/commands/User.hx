//Under GNU AGPL v3, see LICENCE

package beartek.agora.server.commands;

import beartek.agora.types.Tid;

class User {

  public function new() {
    Main.handlers.commands.register_handler('create_user', this.create_user);
  }

  public function create_user( cmd : Array<String> ) : Bool {
    var id : Tid = Main.handlers.user.create_user(cmd[1], cmd[2], cmd[3], Main.handlers.sessions.generate_loginkey(cmd[1], cmd[4]));
    trace( 'User id is ' + id.toString(), 'info' );
    return true;
  }



}
