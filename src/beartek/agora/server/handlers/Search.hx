//Under GNU AGPL v3, see LICENCE

package beartek.agora.server.handlers;

import beartek.agora.types.Types;

class Search {

  public function new() {
    Main.connection.register_get_handler('search', this.on_search);
  }

  //public function search_by_recents( search : Search ) : Search_results {
  //
  //}

  public function random_result() : Search_results {
    var posts : Array<Post_info> = [];

    for( post in Main.handlers.post.get_random(100) ) {
      posts.push(post.info);
    }

    return {posts: posts, sentences: [], users: []};
  }

  private function on_search( id : Int, conn_id : String, search : Search ) : Void {
    if( search == null ) {
      Main.connection.send_search_result(this.random_result(), id, conn_id);
    }


  }

}
