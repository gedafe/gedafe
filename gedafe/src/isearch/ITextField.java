import java.awt.*;
import java.awt.event.*;

class ITextField extends Panel{

    private TextField f;
    public String name;
    public String column;
    private int h=40;
    private int wmax=250;
    private int wmin=70;
    private int wpref=100;

    public ITextField(String col,String value){
	super();
	this.column = col;
	this.name = stripTable(col);
	f = new TextField(value);
	setLayout(null);
	add(f);
    }

    public String stripTable(String colname){
	if(colname.indexOf("_")!=-1)
		colname=colname.substring(
					  colname.indexOf("_")+1,
					  colname.length()
					  );
	
	return colname;
    }

    public ITextField(String name){
	this(name,"");
    }

    public ITextField(String name,String value,int size){
	this(name,value);
	this.wpref = size;
    }


    public ITextField(String name,int size){
	this(name,"");
	this.wpref = size;
    }

    public String getText(){
	return f.getText();
    }

    public void setText(String tmp){
	f.setText(tmp);
    }

    public void update(Graphics g){
	paint(g);
    }

    public void paint(Graphics g){
	g.setColor(Color.black);
	g.drawString(name,10,10);
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
	int textheight = 12;

	f.setBounds(0,textheight,getBounds().width,getBounds().height-textheight);
	validate();
    }


    public void addKeyListener(KeyListener l){
	f.addKeyListener(l);
    }
    
}
