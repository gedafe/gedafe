import java.awt.*;

public class ProgressBar extends Canvas{
    int wpref = 200;
    int wmin = 200;
    int wmax = 200;
    int h = 20;
    int prog = 0;

    public ProgressBar(){
	super();
    }

    public void progress(int prog){
	this.prog =prog;
	repaint();
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

    

    public Dimension getPreferredSize(){
	return new Dimension(wpref,h);
    }

    public Dimension getMinimumSize(){
	return new Dimension(wmin,h);
    }

    public Dimension getMaximumSize(){
	return new Dimension(wmax,h);
    }
   
    public void setSize(Dimension d){
	setSize(d.width,d.height);
    }

    public void setSize(int w,int h){
	super.setSize(w,h);
	updateSize();
    }

    public void setBounds(Rectangle r){
	setBounds(r.x,r.y,r.width,r.height);
    }

    public void setBounds(int x,int y,int w,int h){
	super.setBounds(x,y,w,h);
	updateSize();
    }

    private void updateSize(){
	validate();
    }



}
