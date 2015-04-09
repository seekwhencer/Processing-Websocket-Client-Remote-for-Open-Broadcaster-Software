/*
    OBS Remote Scene
*/
public class ObsScene {

  public ArrayList<ObsSource> sources;
  private String name;

  public ObsScene( String name_ ) {
    this.name = name_;
    this.sources = new ArrayList<ObsSource>();
  }

  public void addSource(String name_, Boolean render_, int index_) {
    sources.add(index_, new ObsSource(name_, render_) );
  }

  public String getName() {
    return name;
  }

  public ObsSource getSource(int index_) {
    return sources.get(index_);
  }
}
