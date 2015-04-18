/*
    OBS Remote Source
*/
public class ObsSource {

  private String name = "";
  private Boolean render = true;
  private Boolean beat = true;

  public ObsSource( String name_, Boolean render_ ) {
    this.name = name_;
    this.render=render_;
  }

  public String getName() {
    return name;
  }

  public Boolean getRender() {
    return render;
  }
  
  public Boolean getBeat(){
    return beat;
  }
  
  
}
