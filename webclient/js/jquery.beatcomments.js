/**
 *  Beat Comments Facebook 
 *  Matthias Kallenbach | Berlin
 *  seekwhencer.de
 * 
 *   
 *  
 */
(function($) {

    var _ns = 'beatcomments';

    var defaults = {
        
        params          : false,
        data            : false,
        setup           : false,
        setup_source    : 'setup.json',

    };

    // build
    $.fn[_ns] = function(args) {

        var target  = this;
        var $target = $(this);
        var options = {};
        var connection = { command:false, obsremote:false };
        var click_break = false;
        var comments = {};
        
        var params  = args;

        if ($.type(options) !== 'object') {
            var options = {};
        }

        $.extend(true, options, defaults, args);
         
        // get the app setup json
        $.ajax( { url: options.setup_source, 
            async       : false,
            dataType    : 'text',
            success     : function(data) {
                options.setup = $.parseJSON(data);
            }
        });
        
        

        // GUI
        var Gui = {               
            drawComments : function(){
                // adds the comments
                console.log(comments.length);
                var m = 0;
                var exists;
                
                var ml          = $(target).find(".message").length;

                
                for(var i=0; i<20; i++){
                    if(comments[i]!=undefined){          
                        exists = $(target).find("div[data-id='"+comments[i].id+"']");  
                        if(comments[i].message != '' && exists.length==0){
                            var comment = $('<div/>',{
                                'data-id'   : comments[i].id,
                                'class'     : 'message',
                                'style'     : 'opacity:0;'
                            });
                            
                            comment.html('<div class="user">'+comments[i].from.name+'</div><div class="text">'+comments[i].message+'</div>');                           
                            
                            if(ml==0){
                                $(target).append(comment);
                            } else {
                                $(target).prepend(comment);
                            }
                            
                            var text = $(comment).find(".text");  
                            GuiBehavior.pingpongTicker(text,'ping');
                            
                            m = m+1;
                        }
                    }
                }
                var margin_max = 70;
                
                var messages = $(target).find(".message");
                
                for(var i=0; i<messages.length; i++){
                    var text = $(messages[i]).find(".text");
                    var margin_to = (margin_max)*i;
                    var opacity_to = 1-((1/19)*(i+1));
                    var is_visible = $(messages[i]).css('opacity');
                    var fontSize = $(text).css('font-size');
                    
                    var mopt = {
                        marginBottom    : margin_to,
                        opacity         : opacity_to
                    };
                    if(i==0){
                        var topt = {
                            fontWeight : 800,
                            fontSize : '8em'  
                        };
                    }
                    
                    if(i>0) {
                        var mopt = {
                            marginBottom    : margin_to + margin_max,
                            opacity         : opacity_to
                        };
                        console.log(fontSize);
                        if(fontSize=='64px') {
                            var topt = {
                                fontWeight : 200,
                                fontSize : '4em'  
                            };
                        }
                    }
                    if(i>1){
                        var topt = {};
                    }
                    
                    
                    $(messages[i]).transition(mopt);

                     
                    $(text).transition(topt);  
                    
                       
                    
                    
                                        
                }
                
            }
            
        }; 
        
        
        
        // GUI Behavior
        var GuiBehavior = {
        
            pingpongTicker : function(text,use){
                var boxWidth= $(target).width();
                var width   = $(text).outerWidth();
                var diff    = width - boxWidth;
                
                if(diff<=0)
                    return;

                console.log(width+' '+boxWidth+' '+diff);
                
                switch(use){
                    case 'pong':
                    margin = 0;
                    use = 'ping';
                    delay = 3000;
                    
                    break;
                    
                    case 'ping':
                    margin = -diff;
                    use = 'pong';
                    delay = 3000;
                    break;
                    
                }
                
                duration = diff*20;
                
                $(text).transit({
                    marginLeft:margin,
                    duration:duration,
                    easing:'linear',
                    delay : delay,
                    complete: function() { 
                        GuiBehavior.pingpongTicker(text,use);
                    }
                });
            }
            
        };
    
        
        // init
        function run(args) {
            
            var that = $(this);
            assumeSettings();
            

            // do things               
            $(document).on('ready',function(){
                connectToCommandServer();
            });

            var timer = setInterval(getComments,10000);
            getComments();
          
            

        }

        



        /**
         *
         * Functions

         *
         */
        
        /*
         * 
         */
        function connectToCommandServer(){
            connection.command = new WebSocket("ws://"+options.setup.cmdServer.host+":"+options.setup.cmdServer.port);
            
            connection.command.onopen = function () {
                console.log('Command Server Opened');
            };
            
            connection.command.onerror = function (error) {
                console.log('Command Server Error ' + error);
            };
            
            connection.command.onclose = function(e){
                console.log('Command Server Closed');
            };
            
            // Log messages from the server
            connection.command.onmessage = function (e) {
              //console.log('Command Server: ' + e.data);
              processCommandServer(e.data);
            };
        }
        
        /*
         * 
         */
        function closeCommandServer(){
            connection.command.close();
        }
        
        /*
         * 
         */
        function processCommandServer(response){
            var data = $.parseJSON(response);
            if(data.facebook_object_id!=undefined){
                options.object_id = data.facebook_object_id;
                $(target).html('');
                console.log('get facebook object id: '+options.object_id);
            }
            
        }
        
        /**
         *
         *  
         */
        function getComments(){
            $.ajax( { url: 'fb.php?object_id='+options.object_id, 
                async       : true,
                dataType    : 'text',
                success     : function(data) {
                    comments = $.parseJSON(data);
                    
                    Gui.drawComments();
                }
            });
        }
        

        

        
        /*
         * 
         */
        function assumeSettings() {
            $.extend(true, options, options.data.settings);
        }

        
        /**
         * 
         */
        function setObjectId(object_id){
            
        }
        
        /**
         *
         *  
         */
        function setAccessToken(access_token){
            
        }
        
        /*
         * 
         */
        function getTemplate(template,replace){
            var output;
            
            $.ajax( { url: template, 
                async       : false,
                dataType    : 'html',
                success     : function(data) {
                    output = data;
                    for(var key in replace){
                        output = output.replace(new RegExp('###'+key+'###','gi'),replace[key]);
                    }
                }
            });
            
            return output;
        }
        
        



        /**
         * the end
         */
        run(options);
        



        return {
            
            // some mapped functions to call from outside
            init        : run,
            setObjectId : setObjectId,
            setAccessToken : setAccessToken
        };
        
        
        
    };

})(jQuery);

