/*
    OBS Remote Scene
*/
public class ObsScene {

  public ArrayList<ObsSource> sources;
  private String name;
  public boolean detection = true;
  public boolean beat = true;

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
  
  public ObsSource getSourceByName(String name){
    for(int i=0; i<this.sources.size(); i++){
      if(this.sources.get(i).name.equals(name)){
        return this.sources.get(i);
      }
    }
    return new ObsSource("empty",false);
  }
  
  public int countBeatSources(){
    int count = 0;
    for(int i=0; i<this.sources.size(); i++){
      if(this.sources.get(i).beat==true){
        count++;
      }
    }
    return count;
  }
  
}
