import java.awt.event.*;
import java.awt.*;
import java.util.*;
import java.net.*;

public class IWindow extends Dialog implements IDataListener{
    Button scan;
    Vector fields;
    ITextField it;
    String data;
    Label exeeded;
    INameBorder rows;
    INameBorder p;
    String[][] db;
    int[] ok;
    int okpointer;
    java.awt.List rowlist;
    URL docbase;
    String url;
    String oldid;
    boolean selected=true;
    boolean exeededbool = false;
    ProgressBar prog;
    IData idata;
    boolean usehid = false;
    

    public IWindow(Vector fields,URL docbase,String url,IData idata,boolean hid){
	super(new Frame(),"Interactive Search ###VERSION###",true);
	this.usehid = hid;
	this.fields = fields;
	this.docbase = docbase;
	this.url = url;
	this.idata = idata;

	addWindowListener(new wh());

	setBounds(100,100,550,400);

	setBackground(Color.lightGray);
	Panel screen = new Panel();
	add(screen,"Center");
	doLayout();

	screen.setLayout(null);
	int width = screen.size().width;

	p = new INameBorder("Fields");
	p.setBounds(2,0,width-11,160);
	p.setLayout(new FlowLayout());
	screen.add(p);
	
	String colname;
	for(int i =0;i<fields.size();i++){
	    colname=(String)fields.elementAt(i);
	    
	    ITextField itf = new ITextField(colname);
	    itf.addKeyListener(new al());
	    p.add(itf);
	}

	scan = new Button("Scan");
	scan.addActionListener(new scanl());
	p.add(scan);


	rows = new INameBorder("Rows");
	rows.setBounds(2,160,width-11,150);
	rows.setLayout(new BorderLayout());
	screen.add(rows);
	exeeded = new Label("Row data exeeds desirable size",Label.CENTER);
	
	Panel bot = new Panel();
	bot.setLayout(new FlowLayout(FlowLayout.RIGHT));
	Button ok = new Button("    OK    ");
	Button cancel = new Button("Cancel");
	prog = new ProgressBar();
	bot.setBounds(2,310,width-11,35);

	ok.addActionListener(new okl());
	cancel.addActionListener(new cancell());
	bot.add(prog);
	bot.add(cancel);
	bot.add(ok);

	screen.add(bot);
	
    }	

    public void progress(int prog){
	this.prog.progress(prog);
    }



    public String getID(String oldid){
	this.oldid = oldid;
	show();
	if(ok!=null&&rowlist!=null&&selected){
	    int idx =0;
	    int returnfield=0;
	    if(usehid){
		for(int h=0;h<fields.size();h++){
		    if(((String)fields.elementAt(h)).endsWith("_hid")){
			returnfield = h;
		    }
		}
	    }
	    if((idx = rowlist.getSelectedIndex())!=-1){
		return db[ok[idx]][returnfield];
	    }
	}
	return (oldid);
    }

    public void scan(){
	rows.removeAll();

	Component[] c = p.getComponents();
	String postfix="";
	for(int i = 0;i<c.length;i++){
	    if(c[i] instanceof ITextField){
		ITextField tmp = (ITextField)c[i];
		String column = tmp.column;
		String value = tmp.getText();
		if(value.length()!=0){
		    postfix +="&field_"+column+"="+UrlEncode(value);
		}    
	    }
	}


	idata.halt();
	idata.loadData(docbase,url+postfix,this);
    }

    public String UrlEncode(String in){
	char[] dat = in.toCharArray();
	StringBuffer s = new StringBuffer();
	char c;
	for(int i =0;i<dat.length;i++){
	    c = dat[i];
	    
	    switch(c){
	    case ' ': {
		s.append('+');
		break;
	    }
	    case '&':{
		s.append("and");
		break;
	    }
	    default: s.append(c);
	    }
	}
	return s.toString();
    }

    public void setData(String data){
	this.data = data;
	parse();
    }

    public void publish(){
	if(exeededbool){
	    sizeExeeded();
	}else{
	    filter();
	    rows.removeAll();
	    rowlist = new java.awt.List(10);
	    
	    for(int i =0;i<okpointer;i++){
		int row = ok[i];
		String line = "";
		for(int j=0;j<fields.size();j++){
		    line += summarize(db[row][j])+" ";
		}
		rowlist.add(line);
	    }
	    rows.add(rowlist,"Center");
	    rows.validate();
	}
    }

    public String summarize(String s){
	if(s.length()<20){
	    return s;
	}
	int l =0;
	int r =0;
	if((l=s.toUpperCase().indexOf("<H1>"))>-1&& (r=s.toUpperCase().indexOf("</H1>"))>-1){
	    return summarize(s.substring(l+4,r));
	}

	if((l=s.toUpperCase().indexOf("<B>"))>-1&& (r=s.toUpperCase().indexOf("<B>",l))>-1){
	    return summarize(s.substring(l+3,r));
	}
	r=s.indexOf("\n");
	if(r>-1&&r<20){
	    return s.substring(0,r);
	}
	    
	return s.substring(0,20);
    }

    public void filter(){
	Component[] c = p.getComponents();
	int fcount = fields.size();
	ITextField[] tf = new ITextField[fcount];
	String[] tv = new String[fcount];
	for(int i = 0;i<c.length;i++){
	    if(c[i] instanceof ITextField){

		ITextField tmp = (ITextField)c[i];
		for(int j=0;j<fields.size();j++){
		   if(tmp.column.equals((String)fields.elementAt(j))){
		       tf[j] = tmp;
		       tv[j] = tmp.getText().toUpperCase();
		    }
		}
	    }
	}
	int dbsize = db.length;
	ok =  new int[dbsize];
	okpointer = 0;
	for(int r = 0;r<dbsize;r++){
	    boolean lineok = true;
	    for(int f = 0;f<fcount;f++){
		
		if(db[r][f].toUpperCase().indexOf(tv[f])==-1){		    
		    lineok = false;
		}
	    }
	    if(lineok){
		ok[okpointer++]=r;
	    }
	}
	
    }

    public void newData(String data){
	setData(data);
    }

    public void parse(){
	StringTokenizer lines = new StringTokenizer(data,"\n");
	if(!lines.hasMoreTokens()){
	    System.out.println("data empy: "+data);
	    return;
	}
	String line = lines.nextToken();
	//contains fieldslist.
	//System.out.println("Fieldlist: "+line);
	line = lines.nextToken();
	int rcount;
	if(line.equals("Resultset exeeds desirable size.")){
	    rcount = 0;
	    exeededbool = true;
	}else{
	    rcount = Integer.parseInt(line);
	    exeededbool = false;
	}
	StringTokenizer fielddata;
	int fcount = fields.size();
	
	db = new String[rcount][fcount];

	String fdat;
	int rownum=0;
	for(int r = 0;r<rcount;r++){
	    line = lines.nextToken();
	    fielddata = new StringTokenizer(line,"\t");
	    
	    for(int f = 0;f<fcount;f++){
		fdat = fielddata.nextToken();
		db[r][f]=fdat;
	    }
	}
	publish();
    }

    public void sizeExeeded(){
	rows.removeAll();
	rows.add(exeeded,"Center");
    }


    public class wh extends WindowAdapter{

	public void windowClosing(WindowEvent e){
	    selected = false;
	    hide();
	}

    }

    public class al extends KeyAdapter{
    
	public void keyReleased(KeyEvent e){
	    publish();
	}
	
    }
    
    public class scanl implements ActionListener{
    
	public void actionPerformed(ActionEvent e){
	    scan();
	}
    
    }

    public class okl implements ActionListener{
    
	public void actionPerformed(ActionEvent e){
	    if(rowlist!=null&&rowlist.getSelectedIndex()!=-1){
	       selected = true;
	       hide();
	    }
	}
    
    }

    public class cancell implements ActionListener{
    
	public void actionPerformed(ActionEvent e){
	    selected = false;
	    hide();
	}
    
    }



}
