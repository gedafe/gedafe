import java.applet.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;
import java.io.*;


public class ISearch extends Applet implements IDataListener{
    String data;
    int id;
    int prog =0;
    IData idata;

    public void init(){
	idata = new IData(getDocumentBase());
	idata.loadData(getDocumentBase(),getParameter("url"),this);
    }


    public void newData(String data){
	this.data = data;
    }

    public void progress(int prog){
	this.prog =prog;
	repaint();
	//paint(getGraphics());
    }

    public void paint(Graphics g){
	g.setColor(Color.white);
	g.fillRect(0,0,size().width-1,size().height-1);
	g.setColor(new Color(200,200,255));
	int complete = (int)((prog/100f)*size().width-1);
	g.fillRect(0,0,complete,size().height-1);	
	g.setColor(Color.black);
	g.drawRect(0,0,size().width-1,size().height-1);
	String text;
	if(prog==100){
	    text = "Ready!";
	}else{
	    text = "Reading...";
	}
	g.drawString(text,2,13);
    }

    public String getID(String oldid){
	
	return isearch(oldid);
    }

    public String isearch(String oldid){
	if(data==null)return oldid;
	String tmp=data.substring(0,data.indexOf("\n"));
	String databody = data.substring(data.indexOf("\n")+1,data.length());
	String field;
	StringTokenizer t = new StringTokenizer(tmp,"\t");
	Vector fields = new Vector();
	while(t.hasMoreTokens()){
	    field = t.nextToken();
	    fields.addElement(field);
	}
        String testhid="true";
	boolean hid = false;
	if(testhid.equals(getParameter("hid"))){
	    hid=true;
	}else{
	    hid=false;
	}
	IWindow i = new IWindow(fields,getDocumentBase(),getParameter("url"),idata,hid);
	i.setData(data);
	i.progress(100);
	return i.getID(oldid);
    }

}
