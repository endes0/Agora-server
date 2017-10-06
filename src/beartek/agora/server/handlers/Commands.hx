//Under GNU AGPL v3, see LICENCE

package beartek.agora.server.handlers;

import beartek.agora.server.commands.*;

class Commands {
  var cmds_handlers : Map<String,Array<Array<String> -> Bool>> = new Map();
  var started : Bool = false;

  public function new() {
    haxe.Timer.delay(this.start_commands, 10);
  }

  public function command( cmd_args : Array<String> ) : Bool {
    if( started == false ) {
      this.start_commands();
    }

    var cmd : String = cmd_args[0].toLowerCase();
    if( cmds_handlers[cmd] != null && cmds_handlers[cmd].length >0 ) {
      for( func in cmds_handlers[cmd] ) {
        func(cmd_args);
      }

      return true;
    } else {
      return false;
    }
  }

  public function register_handler( cmd : String, func : Array<String> -> Bool ) : Int {
    cmd = cmd.toLowerCase();
    if(cmds_handlers[cmd] != null){
      return cmds_handlers[cmd].push(func);
    } else {
      cmds_handlers[cmd] = [func];
      return 0;
    }
  }

  public function remove_handler( cmd : String, id : Int ) : Void {
    cmd = cmd.toLowerCase();
    cmds_handlers[cmd][id] = null;
  }

  public function list() : Array<String> {
    var list : Array<String> = [];
    for( key in cmds_handlers.keys() ) {
      list.push(key);
    }

    return list;
  }

  private function start_commands() : Void {
    new Core();

    started = true;
  }

}
