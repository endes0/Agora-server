//Under GNU AGPL v3, see LICENCE

package beartek.agora.server.handlers;

import beartek.agora.types.Types;
import beartek.agora.types.Tid;

@:keep class Search {
  var posts_info : models.PostsInfoManager = Main.db.postsInfo;

  public function new() {
    Main.connection.register_get_handler('search', this.on_search);
  }

  public function random_result() : Search_results {
    return {posts: Main.handlers.post.get_random(100), sentences: [], users: []};
  }

  public function get_posts( search : beartek.agora.types.Types.Search ) : Array<Post_info> {
    var where : Array<String> = [];
    var other : String = '';

    if( search.contain != null ) {
      var contain : String = Main.db_conn.quote('%' + search.contain + '%');
      where.push( 'title LIKE ' + contain + ' OR subtitle LIKE ' + contain + ' OR overview LIKE ' + contain );
    }
    if( search.dont_contain != null ) {
      var contain : String = Main.db_conn.quote('%' + search.dont_contain + '%');
      where.push( 'NOT title LIKE ' + contain + ' AND NOT subtitle LIKE ' + contain + ' AND NOT overview LIKE ' + contain );
    }
    if( search.starts_with != null ) {
      var start : String =  Main.db_conn.quote(search.starts_with + '%');
      where.push( 'title LIKE ' + start + ' OR subtitle LIKE ' + start + ' OR overview LIKE ' + start );
    }
    //TODO: event, topic, tags

    if( search.order_by != null ) {
      switch search.order_by {
      case Recent_date:
        other += 'ORDER BY publish_date DESC ';
      case Older_date:
        other += 'ORDER BY publish_date ASC ';
      case Most_popular_over_time:
        other += 'ORDER BY total_popularity DESC ';
      case Least_popular_over_time:
        other += 'ORDER BY total_popularity ASC ';
      case Most_popular:
        where.push('last_access > ' + datetime.DateTime.now().snap(Day(Down)).getTime());
        other += 'ORDER BY day_popularity DESC ';
      case Least_popular:
        where.push('last_access > ' + datetime.DateTime.now().snap(Day(Down)).getTime());
        other += 'ORDER BY day_popularity ASC ';
      case _:
        throw 'Not yet implemented';
      }
    }
    if( search.limit != null && search.limit < 100 ) {
      other += 'LIMIT ' + search.limit + ' ';
    } else {
      other += 'LIMIT 100 ';
    }
    if( search.offset != null ) {
      other += 'OFFSET ' + search.offset;
    }

    return posts_info.getBySqlMany('SELECT * FROM posts_info' + (if(where.length > 0) ' WHERE ' + where.join(' AND ') else ' ') + ' ' + other).map(Main.handlers.post.to_post_info);
  }

  private function on_search( id : Int, conn_id : String, search : beartek.agora.types.Types.Search ) : Void {
    if( search == null ) {
      Main.connection.send_search_result(this.random_result(), id, conn_id);
    } else {
      Main.connection.send_search_result({posts: this.get_posts(search), sentences: [], users: []}, id, conn_id);
    }


  }

}
