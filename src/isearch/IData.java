import java.net.*;
import java.io.*;

public class IData implements Runnable{
    private String url;
    private URL docbase;
    private static IData trans;
    public boolean running = false;
    private IDataListener listener;

    public IData(URL docbase){
	this.docbase = docbase;
    }

    public static void loadData(URL docbase,String url,IDataListener listener){
	if(trans==null)trans = new IData(docbase);
	if(trans.running)return;
	Thread t = new Thread(trans);
	trans.setUrl(url);
	trans.setListener(listener);
	t.start();
    } 

    public void setUrl(String url){
	this.url = url;
    }

    public void setProgress(int prog){
	System.out.println("Progress is now: "+prog+"%");
	listener.progress(prog);
    }

    public void setListener(IDataListener l){
	listener = l;
    }

    public static void halt(){
	if(trans!=null)trans.running = false;
    }

    public void run(){
	    running = true;
	    try{
		URL u = new URL(docbase,url);
		DataInputStream in = new DataInputStream(u.openStream());
		String line;
		String data="";
		int size = 0;
		line = in.readLine();
		if(line!=null)data+=line+"\n";
		//data contains fields list;
		line = in.readLine();
		if(line!=null)data+=line+"\n";
		//data now also contains resultset size;
		if(line!=null){
		    //parse size;
		    if(line.equals("Resultset exeeds desirable size.")){
			size =0;
			setProgress(100);
		    }else{
			size =Integer.parseInt(line);
		    }
		}
		int rowcounter = 0;
		int progress = 0;
		while((line=in.readLine())!=null&&running){
		    progress = (int)((rowcounter*100f)/size);
		    if(progress%10==0)setProgress(progress);
		    data+=line+"\n";
		    rowcounter++;
		}
		if(running){
		    setProgress(100);
		    listener.newData(data);
		}
	    }catch(Exception e){
		e.printStackTrace();
	    }
	    
	    running = false;
    }

}


