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
                var exists;
                var ml = $(target).find(".message").length;

                for(var i=0; i<20; i++){
                    if(comments[i]!=undefined){          
                        exists = $(target).find("div[data-id='"+comments[i].id+"']");
                        
                        // adds one message to the html stack
                        if(comments[i].message != '' && exists.length==0){
                            var comment = $('<div/>',{
                                'data-id'   : comments[i].id,
                                'class'     : 'message',
                                'style'     : 'opacity:0;'
                            });
                            
                            comment.html('<div class="user">'+comments[i].from.name+'</div><div class="scroll"><div class="text">'+comments[i].message+'</div></div>');                           
                            
                            if(ml==0){
                                $(target).append(comment);
                            } else {
                                $(target).prepend(comment);
                            }
                        }
                    }
                }

                // move it                
                var margin_max = 70;
                var messages = $(target).find(".message");
                $.each(messages,function(i,message){
                    
                    var text    = $(message).find('.text');
                    var size    = parseInt($(text).css('font-size').replace('px',''));
                    
                    var margin_to   = (margin_max)*i;
                    var opacity_to  = 1-((1/19)*(i+1));
                                        
                    var mopt = {
                        
                    };
                    
                    var topt = {
                        complete : function(){
                            GuiBehavior.pingPongTicker(message);
                        }
                    };
                    
                    //
                    if(i==0){
                       $(message).css({'font-weight':800});
                       
                       mopt['opacity'] = 1;                       
                       topt['fontSize'] = 128;
                    }
                    
                    if(i>0){
                        mopt['marginBottom'] = margin_to + margin_max;
                        mopt['opacity']      = opacity_to;
                       
                        topt['fontSize']     = 64;
                        topt['fontWeight']   = 200;
                        
                        if(size>64){
                            console.log(i);
                            var scroll = $(message).find('.scroll');
                            $(scroll).transitStop();
                            $(scroll).css({'margin-left':'0px'});
                            $(message).prop({scrolling:false});
                        }
                        
                    }
                    
                    $(message).transition(mopt);
                    $(text).transition(topt);
                });
                
                // remove the other over 20
                
                var messages = $(target).find('.messages');
                for(var i=messages.length; i==messages.length-19; i--){
                    $(messages[i]).remove();
                }
                
                var messages = $(target).find('.messages');
                console.log(messages.length);
                
            }
        }; 
        
        
        
        // GUI Behavior
        var GuiBehavior = {
            
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

            var timer = setInterval(getComments,15000);
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

