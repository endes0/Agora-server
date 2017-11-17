//Under GNU AGPL v3, see LICENCE

package beartek.agora.server.handlers;

import beartek.agora.types.Types;
import beartek.agora.types.Tid;
import beartek.agora.types.Tsentence;

@:keep class Search {
  var posts_info : models.PostsInfoManager = Main.db.postsInfo;
  var users_info : models.UsersInfoManager = Main.db.usersInfo;
  var sentences : models.SentencesManager = Main.db.sentences;


  public function new() {
    Main.connection.register_get_handler('search', this.on_search);
  }

  public function random_result() : Search_results {
    return {posts: Main.handlers.post.get_random(100), sentences: Main.handlers.sentence.get_random(100), users: []};
  }

  private function generate_query( text_rows : Array<String>, order_rows : Array<String>, search : beartek.agora.types.Types.Search ) : String {
    var where : Array<String> = [];
    var other : String = '';

    if( search.contain != null ) {
      var contain : String = Main.db_conn.quote('%' + search.contain + '%');
      var conditions : Array<String> = [];
      for( row in text_rows ) {
        conditions.push(row + ' LIKE ' + contain);
      }

      where.push( conditions.join(' OR ') );
    }
    if( search.dont_contain != null ) {
      var contain : String = Main.db_conn.quote('%' + search.dont_contain + '%');
      var conditions : Array<String> = [];
      for( row in text_rows ) {
        conditions.push('NOT' + row + ' LIKE ' + contain);
      }

      where.push( conditions.join(' AND ') );
    }
    if( search.starts_with != null ) {
      var start : String =  Main.db_conn.quote(search.starts_with + '%');
      var conditions : Array<String> = [];
      for( row in text_rows ) {
        conditions.push(row + ' LIKE ' + start);
      }

      where.push( conditions.join(' OR ') );
    }
    //TODO: event, topic, tags

    if( search.order_by != null ) {
      //TODO: anadir casos especiales para el tipo de item;
      switch search.order_by {
      case Recent_date:
        other += 'ORDER BY ' + order_rows[0] + ' DESC ';
      case Older_date:
        other += 'ORDER BY ' + order_rows[0] + ' ASC ';
      case Most_popular_over_time:
        other += 'ORDER BY ' + order_rows[1] + ' DESC ';
      case Least_popular_over_time:
        other += 'ORDER BY ' + order_rows[1] + ' ASC ';
      case Most_popular:
        where.push('last_access > ' + datetime.DateTime.now().snap(Day(Down)).getTime());
        other += 'ORDER BY ' + order_rows[2] + ' DESC ';
      case Least_popular:
        where.push('last_access > ' + datetime.DateTime.now().snap(Day(Down)).getTime());
        other += 'ORDER BY ' + order_rows[2] + ' ASC ';
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

    return (if(where.length > 0) ' WHERE ' + where.join(' AND ') else ' ') + ' ' + other;
  }

  public inline function get_posts( search : beartek.agora.types.Types.Search ) : Array<Post_info> {
    return posts_info.getBySqlMany('SELECT * FROM posts_info' + generate_query(['title', 'subtitle', 'overview'], ['publish_date', 'total_popularity', 'day_popularity'], search) ).map(Main.handlers.post.to_post_info);
  }

  public inline function get_sentences( search : beartek.agora.types.Types.Search ) : Array<Sentence> {
    return sentences.getBySqlMany('SELECT * FROM sentences' + generate_query(['sentence'], ['publish_date', 'total_popularity', 'day_popularity'], search)).map( function( sent : models.Sentences ) : Sentence {
      return Main.handlers.sentence.to_sentence(sent).get();
    });
  }

  public inline function get_users( search : beartek.agora.types.Types.Search ) : Array<User_info> {
    return users_info.getBySqlMany('SELECT * FROM users_info' + generate_query(['username', 'join_date', 'first_name'], ['last_login', 'username', 'first_name'], search)).map(Main.handlers.user.to_user_info);
  }

  private function on_search( id : Int, conn_id : String, search : beartek.agora.types.Types.Search ) : Void {
    if( search == null ) {
      Main.connection.send_search_result(this.random_result(), id, conn_id);
    } else {
      if( search.type == null ) {
        Main.connection.send_search_result({posts: this.get_posts(search), sentences: this.get_sentences(search), users: this.get_users(search)}, id, conn_id);
      } else {
        Main.connection.send_search_result({posts: if(search.type.indexOf(Post_item) != -1) this.get_posts(search) else [],
                                            sentences: if(search.type.indexOf(Sentence_item) != -1) this.get_sentences(search) else [],
                                            users: if(search.type.indexOf(User_item) != -1) this.get_users(search) else []}, id, conn_id);
      }
    }


  }

}
