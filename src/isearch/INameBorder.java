import java.awt.*;

public class INameBorder extends Panel{
    private String name;
    private FontMetrics fm;
    private int namesize = 0;

    public INameBorder(String name){
	super();
	this.name = name;
	
    }

    public Insets insets(){
	return getInsets();
    }

    public Insets getInsets(){
	return new Insets(15,2,2,2);
    }

    public void paint(Graphics g){

	if(fm==null)fm=getFontMetrics(getFont());
	if(namesize==0)namesize = fm.stringWidth(name);
	Rectangle r = getBounds();
	g.setColor(Color.black);
	int y=(int)(fm.getHeight()/2.0);
	g.drawLine(0,y,y,y);
	g.drawLine(0,y,0,r.height-1);
	g.drawLine(0,r.height-1,r.width-1,r.height-1);
	g.drawLine(r.width-1,r.height-1,r.width-1,y);
	g.drawLine(r.width-1,y,namesize+3*y,y);
	g.drawString(name,2*y,2*y);
    }
}
