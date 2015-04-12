/**
 *  Beatsocket Client Interface
 *  Matthias Kallenbach | Berlin
 *  seekwhencer.de
 * 
 *   
 *  
 */
(function($) {

    var _ns = 'beatsocket';

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
            
            drawScenes : function(){
                
                var scenesRow = $('<div/>',{
                    id : 'RowScenes',
                    class : 'col-xs-3'
                });
                for(var i in options.scenes){
                    var sceneButton = $('<button/>',{
                       class    : 'btn btn-scene col-xs-12',
                       text     : options.scenes[i].name,
                       "data-name" : options.scenes[i].name
                    });
                    sceneButton.on('click',GuiBehavior.sceneButton);
                    scenesRow.append(sceneButton);
                }
                $target.html(scenesRow);
                
                Gui.drawSources(options.current_scene);
                Gui.drawBeatSources(options.current_scene);
            },
            
            drawSources : function(scene){
                var sourcesRow = $('<div/>',{
                    id : 'RowSources',
                    class : 'col-xs-7'
                });
                
                for(var i in options.scenes){
                    if(options.scenes[i].name == scene){
                        for(var ii in options.scenes[i].sources){
                            var sourceButton = $('<button/>',{
                               class    : 'btn btn-source col-xs-12',
                               text     : options.scenes[i].sources[ii].name,
                               "data-name" : options.scenes[i].sources[ii].name
                            });
                            
                            if(options.scenes[i].sources[ii].render==true){
                                sourceButton.addClass('active');
                            }
                            
                            if(options.scenes[i].sources[ii].beat==true){
                                sourceButton.addClass('beat');
                            }
                            
                            sourceButton.on('click',GuiBehavior.sourceButton);
                            sourcesRow.append(sourceButton);
                        }
                    }
                }
                
                $target.append(sourcesRow);
                
                
            },
            
            drawBeatSources : function(scene){
                var sourcesRow = $('<div/>',{
                    id : 'RowBeatSources',
                    class : 'col-xs-2'
                });
                
                for(var i in options.scenes){
                    if(options.scenes[i].name == scene){
                        for(var ii in options.scenes[i].sources){
                            var beatsourceButton = $('<button/>',{
                               class    : 'btn btn-beat col-xs-12',
                               text     : 'BP',
                               "data-beat" : options.scenes[i].sources[ii].name
                            });
                            
                            if(options.scenes[i].sources[ii].beat==true){
                                beatsourceButton.addClass('active');
                            }
                            
                            beatsourceButton.on('click',GuiBehavior.beatsourceButton);
                            sourcesRow.append(beatsourceButton);
                        }
                    }
                }
                
                $target.append(sourcesRow);
                
            }
            
              
        }; 
        
        
        
        
        // GUI Behavior
        var GuiBehavior = {
            sceneButton : function(){
                connection.command.send(JSON.stringify({"toggle-scene":$(this).text()}));
                $(this).toggleClass('active');
                console.log("toggle scene: "+$(this).text());
            },
            
            sourceButton : function(){
                connection.command.send(JSON.stringify({"toggle-source":$(this).text()}));
                $(this).toggleClass('active');
                $(this).removeClass('beat');
                console.log("toggle source: "+$(this).text());
            },
            
            beatsourceButton : function(){
                connection.command.send(JSON.stringify({"toggle-beat-source":$(this).data('beat')}));
                $(this).toggleClass('active');
                console.log("toggle beat source: "+$(this).data('beat'));
            }
        };
    
        
        // init
        function run(args) {
            
            var that = $(this);
            assumeSettings();
            
            $('#btnConnect').on('click',function(){
                connectToCommandServer();
            });
            
            $('#btnDisconnect').on('click',function(){
                closeCommandServer();
            });
            
            
            
            // do things               
            
            

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
                $('#btnConnect').hide();
                $('#btnDisconnect').show();
            };
            
            connection.command.onerror = function (error) {
                $('#btnConnect').show();
                $('#btnDisconnect').hide();
                console.log('Command Server Error ' + error);
            };
            
            connection.command.onclose = function(e){
                $('#btnConnect').show();
                $('#btnDisconnect').hide();
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
            
            if(data.source!=undefined){
                $("#RowSources button.beat").removeClass('active');
                $("button[data-name='"+data.source+"']").toggleClass('active');
            }
            
            if(data.scene!=undefined){
                $("#RowScenes button").removeClass('active');
                $("button[data-name='"+data.scene+"']").toggleClass('active');
                
                console.log('Get Scene: '+data.scene);
            
            }
            if(data.scenes!=undefined){
                options.scenes = data.scenes;
                Gui.drawScenes();                      }
            
            if(data.current_scene!=undefined){
               options.current_scene = data.current_scene;
               $("#RowScenes button").removeClass('active');
               $("button[data-name='"+options.current_scene+"']").toggleClass('active');
               //console.log('Current Scene: '+options.current_scene);
            }
        }
        
        /*
         * 
         */
        function assumeSettings() {
            $.extend(true, options, options.data.settings);
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
            init    : run
        };
        
        
        
    };

})(jQuery);

