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
        max_comments    : 12

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
            
            drawComments : function(mi){
              
                if(mi==undefined){
                    if(comments.length<options.max_comments){
                        var mi = 0;
                    } else {
                        var mi = comments.length-options.max_comments-1;
                    }
                }
                    
                // break the chain
                if(comments[mi]==undefined)
                    return;

                   
                var ml      = $(target).find(".message").length;
                var exists  = $(target).find("div[data-id='"+comments[mi].id+"']");
                
                if(exists.length==0){
                    var comment = $('<div/>',{
                        'data-id'   : comments[mi].id,
                        'class'     : 'message',
                        'style'     : 'opacity:0;'

                    });
                    
                    comment.html('<div class="user">'+comments[mi].from.name+' '+comments[mi].created_time+'</div><div class="scroll"><div class="text">'+comments[mi].message+'</div></div>');                           
                    $(target).prepend(comment);
                    
                    $(target).find('.message').eq(options.max_comments+1).remove();

                    console.log('inserted: '+comments[mi].id+' from: '+comments[mi].from.name);
                    GuiBehavior.animateMessage(mi);
                } else {

                    console.log('exists: '+comments[mi].id+' from: '+comments[mi].from.name);
                    Gui.drawComments(mi+1);
                }

            }
        }; 
        
        
        
        // GUI Behavior
        var GuiBehavior = {
            
            
            animateMessage : function(mi){
                var messages        = $(target).find(".message");
                var margin_message  = 70;
                
                $.each(messages,function(i,message){
                    
                    var text    = $(message).find('.text');
                    var size    = parseInt($(text).css('font-size').replace('px',''));
                    
                    var margin_to   = margin_message*i;
                    var opacity_to  = 1-((1/(options.max_comments))*(i+1));
                    
                    var mopt = {
                        marginBottom    : margin_to,
                        opacity         : 1,
                        duration        : 500,
                        complete        : function(){
                            GuiBehavior.pingPongTicker(message);
                                                        
                            if(i==messages.length-1) // trigger at the last
                                Gui.drawComments(mi+1);
                        }
                    };
                    
                    var topt = {
                        fontSize : 128
                    };

                    if(i==0){
                       $(message).css({'font-weight':800});                  
                    }
                    
                    if(i>0){
                        mopt['marginBottom'] = margin_to + margin_message;
                        mopt['opacity']      = opacity_to;
                       
                        topt['fontSize']     = 64;
                        topt['fontWeight']   = 200;
                        
                        if(size>64){
                            var scroll = $(message).find('.scroll');
                            $(scroll).transitStop();
                            $(scroll).css({'margin-left':'0px'});
                            $(message).prop({scrolling:false});
                        }
                        
                    }
                       
                    
                    $(message).transition(mopt);
                    $(text).transition(topt);
                    
                });
            },
            
            
            
            
            /**
             * 
             */
            pingPongTicker : function(message){

                if($(message).prop('scrolling')==true)
                    return;
                
                                
                var scroll  = $(message).find('.scroll');
                var text    = $(message).find('.text');
                var size    = parseInt($(text).css('font-size').replace('px',''));
                
                var boxWidth= $('body').width();
                var width   = $(scroll).outerWidth();
                
                var diff    = width - boxWidth;
                var actual  = parseInt($(scroll).css('margin-left').replace('px',''));
                

                if(diff<=0){
                    return;
                }
                
                $(message).prop({scrolling:true});    
                
                var sopt    = {
                    easing      : 'linear',
                    delay       : 0000,
                    duration    : diff*20,
                    complete    : function(){
                        $(message).prop({scrolling:false});
                        GuiBehavior.pingPongTicker(message);
                    }
                };
                                
                if(actual==0 || actual==-1) {
                    sopt.marginLeft = -diff;
                }
                if(actual<-1){
                    sopt.marginLeft = 0;
                }
                
                if($(message).index()>0 && size > 64){
                    sopt.marginLeft = 0;
                }
                
                //console.log('scroll: '+$(message).index()+' from: '+actual+' to: '+sopt.marginLeft);
                $(scroll).transit(sopt);
                
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

            var timer = setInterval(function(){
                getComments();
            },15000);
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
                    console.log('getting comments complete');
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

