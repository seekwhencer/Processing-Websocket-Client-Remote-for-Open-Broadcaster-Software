    
    var beatsocket;
    
    $(document).ready(function(){

        $('a, button').on('click',function(){
            var that = this;
            setTimeout( function(){
                that.blur();
            },250);
        });
        
        beatsocket = $('#beatsocket').beatsocket();
        
        
    });