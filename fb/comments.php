<?php

    require 'config.php';
    
    if($_GET['object_id']){
        $conf['object_id'] = $_GET['object_id'];
    }
    
    $long_token_json = implode(file('log/token'));
    $long_token = json_decode($long_token_json,true);
      
    if($long_token['access_token']){
        $conf['access_token'] = $long_token['access_token'];
    }
    
    
    require __DIR__ . '/sdk/autoload.php';   
    
    use Facebook\FacebookSession;
    use Facebook\FacebookRequest;
    
    FacebookSession::setDefaultApplication($conf['app_id'], $conf['app_secret']);
    $session = new FacebookSession($conf['access_token']);    
    
    
    $fh = fopen('log/get/comments','w+');
    fwrite($fh,json_encode($_GET));
    fclose($fh);
    
    $fh = fopen('log/post/comments','w+');
    fwrite($fh,json_encode($_POST));
    fclose($fh);
    
    
    // To validate the session:
    try {
      $session->validate();
    } catch (FacebookRequestException $ex) {
      // Session not valid, Graph API returned an exception with the reason.
      echo $ex->getMessage();
    } catch (\Exception $ex) {
      // Graph API returned info, but it may mismatch the current app or have expired.
      echo $ex->getMessage();
    }
    
    
    // get comments count
    $requestUrl = '/'.$conf['object_id'].'/comments?order=chronological&filter=toplevel&summary=1&limit=0';
    $request = new FacebookRequest($session,'GET',$requestUrl);
    $response = $request->execute();
    $graphObject = $response->getGraphObject()->asArray();
    
    $count      = array(
        'total_count' => $graphObject['summary']->total_count
    );
   
    $fh = fopen('log/comments_count.json','w+');
    fwrite($fh,json_encode($count));
    fclose($fh);
    
    
    // get comments - but: "total_count can be greater than or equal to the actual number of comments returned due to privacy or deletion"
    $requestUrl = '/'.$conf['object_id'].'/comments?order=chronological&filter=toplevel&limit=10000&offset='.intval($count['total_count']*0.5);
    $request = new FacebookRequest($session,'GET',$requestUrl);
    $response = $request->execute();
    $graphObject = $response->getGraphObject()->asArray();

    $fh = fopen('log/comments_graph.json','w+');
    fwrite($fh,json_encode($graphObject));
    fclose($fh);


    $comments = $graphObject['data'];
    
    // clear empty comments
    $cleared_comments = array();
    foreach($comments as $c){
        if($c->message!='')
            $cleared_comments[]=$c;
    } 
    
    $fh = fopen('log/comments.json','w+');
    fwrite($fh,json_encode($cleared_comments));
    fclose($fh);
   
    
?>
<?= json_encode($cleared_comments,true); ?>