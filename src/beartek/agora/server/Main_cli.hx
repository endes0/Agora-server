//Under GNU AGPL v3, see LICENCE
//Third-party code: haxe-hant by yar3333 under LGPL

package beartek.agora.server;

import datetime.DateTime;
import com.thomasuster.threadpool.ThreadPool;

class Main_cli {
  var queque_cmd : String = '';
  var pool : ThreadPool = new ThreadPool(2);

  public function new() {
    Sys.println('Starting Agora web server.');

    haxe.Log.trace = this.trace;
    this.print_insert();

    Main.start();

    pool.addConcurrent(function( t : Int ) : Void {
      while( Main.on ) {
        try {

          Main.connection.refresh();
        } catch(e:Dynamic) {
          trace('An error ocurred: ' + e);
        }
        Sys.sleep(0.1);
      }
    });

    pool.addConcurrent(function( t : Int ) : Void {
      while( Main.on ) {
        this.wait_for_command();
      }
    });

    pool.blockRunAll();
    pool.end();
  }

  public function wait_for_command() : Void {
    var cmd : String = this.readLine();
    if( cmd != '' ) {
      Sys.println("");

      var cmd_args : Array<String> = cmd.split(' ');
      cmd_args[0].toLowerCase();

      if( Main.handlers.commands.command(cmd_args) ) {
        Sys.println( 'Command executed sucesfull.' );
      } else {
        Sys.println( 'Command not found.' );
      }

      this.print_insert();
    }
  }

  public inline function print_insert() : Void {
    Sys.print('❱ ' + queque_cmd);
  }

  public function trace( v:Dynamic, ?infos:haxe.PosInfos ) : Void {
    this.back_to_column(0);
    Sys.println('[' + DateTime.now().toString() + '][' + infos.className + ':' + infos.methodName + ']:' + Std.string(v));
    this.print_insert();
  }

  private inline function back_to_column( n : Int ) : Void {
    Sys.print("\033[" + (2 + queque_cmd.length - n) + "D");
  }

  private function line_up( n : Int ) : Void {
    Sys.print("\033[" + n + "A");
  }

  private function line_down( n : Int ) : Void {
    Sys.print("\033[" + n + "B");
  }

  private function readLine(displayNewLineAtEnd=false) : String {
		while (true) {
			var c = Sys.getChar(false);
			if (c == 13) break;
			if (c == 8) {
				if (queque_cmd.length > 0) {
					queque_cmd = queque_cmd.substring(0, queque_cmd.length - 1);
					Sys.print(String.fromCharCode(8) + " " + String.fromCharCode(8));
				}
			} else {
				queque_cmd += String.fromCharCode(c);
				Sys.print(String.fromCharCode(c));
			}
		}
		if (displayNewLineAtEnd) Sys.println("");
    var s : String = queque_cmd;
    queque_cmd = '';
		return s;
	}

  static inline function main() : Void {
    new Main_cli();
  }

}
