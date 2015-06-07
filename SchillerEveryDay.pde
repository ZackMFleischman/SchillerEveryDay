//
// schiller.pde
// author: Zack Fleischman
//
// This formats Schiller's Pic-a-day's into a finished image.
//

import java.util.concurrent.TimeUnit;
import java.io.File;
import javax.swing.JOptionPane;
import javax.swing.JFileChooser;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.border.EmptyBorder; 
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.Date;
import java.util.Calendar;
import java.text.*;


// Params
boolean autoChoose=false;
boolean onlyFirst=false;

// Globals
int fileIndex = 0;
boolean inputReady = false;
boolean outputReady = false;
boolean processing = false;

PGraphics s;
PImage source;
PImage display;

int displayWidth = 360;
int displayHeight = 640;
int ratio = 3;

String outputDirectory = "";

ArrayList<SchillerPic> picsToProcess = new ArrayList<SchillerPic>();

boolean setLocationOnStart = true;

// Font
PFont f;

// 
// Program starts here.
//
void setup() {

    f = createFont("Helvetica-Bold",16,true);
    

    if (autoChoose) {
        setDefaultPaths();
    } else {
        createAndShowGui();
    }

    size(displayWidth, displayHeight);
    if (!autoChoose) {
        noLoop();
    }
}

//
// Called after setup() finishes.
//
int numFilesWritten = 1;
void draw() {

    // Set window location the first time around
    if (!autoChoose && setLocationOnStart) {
        frame.setLocation(800, 100);
        setLocationOnStart = false;
    }

    if (processing) {

        if ((!onlyFirst && fileIndex < picsToProcess.size()) || (onlyFirst && fileIndex == 0)) {

            SchillerPic currentPic = picsToProcess.get(fileIndex);

            // Load image
            source = loadImage(currentPic.inputFile.getAbsolutePath());
            display = loadImage(currentPic.inputFile.getAbsolutePath());
            display.resize(displayWidth, displayHeight);
            s = createGraphics(source.width, source.height);

            // Show image
            s.beginDraw();
            s.image(source, 0, 0);
            image(display, 0, 0);

            // Process
            addImageDecorations(currentPic);

            s.endDraw();

            String output = outputDir.getAbsolutePath() + "/" + currentPic.outputString;
            if (!autoChoose) {
                progressLabel.setText("  Status: Processing pic " + numFilesWritten + "/" + picsToProcess.size() + "..."); 
            }
            System.out.println("Saving File " + numFilesWritten++ + ": " + output);
            s.save(output);

            fileIndex++;

            if (onlyFirst) {
                noLoop();
            }
        } else {
            System.out.println("Done!");
            if (!autoChoose) {
                progressLabel.setText("  Status: Done!"); 
                picsToProcess.clear();
                fileIndex = 0;
                numFilesWritten = 1;
                goBtn.setEnabled(true);
                inputBtn.setEnabled(true);
                outputBtn.setEnabled(true);
                noLoop();
            } else {
                System.exit(0);
            }
        }
    } else {
        controlFrame.requestFocus();
    }
}

void keyPressed() {
    if (key == 'q') {
        System.exit(0);
    }
} 


///////////////////////////

File inputDir = null;
File outputDir = null;
void go() {
    if (inputDir == null || outputDir == null) {
        error("Directories are invalid!");
        System.exit(1);
    }

    if (!autoChoose) {
        inputBtn.setEnabled(false);
        outputBtn.setEnabled(false);
    }

    // Process the input files
    File[] directoryListing = inputDir.listFiles();
    if (directoryListing != null) {
        for (File child : directoryListing) {
            processFile(child);
        }
    }

    processing = true;
    if (!autoChoose) {
        loop();
    }
}

JButton inputBtn = new JButton("Choose Image Input Directory");
JLabel inputLabel = new JLabel("  Input Dir: \"<None>\"");
JButton outputBtn = new JButton("Choose Image Output Directory");
JLabel outputLabel = new JLabel("  Output Dir: \"<None>\"");
JButton goBtn = new JButton("Run!");
JLabel progressLabel = new JLabel("  Status: Choose input and output directories...");
JFrame controlFrame = new JFrame("Schiller Every Day");
void createAndShowGui() {
    goBtn.setEnabled(false);

    controlFrame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE); 

    JPanel guiPanel = new JPanel();
    guiPanel.setLayout(new BoxLayout(guiPanel, BoxLayout.Y_AXIS));
    guiPanel.setBorder(new EmptyBorder(10, 10, 10, 10) );

    // Set Action Listeners
    inputBtn.addActionListener(new ActionListener()
            {
            public void actionPerformed(ActionEvent e)
            {
            inputDir  = getImageDirectory();
            if (inputDir != null) {
            inputLabel.setText("  Input Dir: \"" + inputDir.getAbsolutePath() + "\"");
            inputReady = true;
            }

            if (inputReady && outputReady) {
            goBtn.setEnabled(true);
            }
            }
            });
    outputBtn.addActionListener(new ActionListener()
            {
            public void actionPerformed(ActionEvent e)
            {
            outputDir = getOutputDirectory();
            if (outputDir != null) {
            outputLabel.setText("  Output Dir: \"" + outputDir.getAbsolutePath() + "\"");
            outputReady = true;
            }
            if (inputReady && outputReady) {
            goBtn.setEnabled(true);
            }
            }
            });
    goBtn.addActionListener(new ActionListener()
            {
            public void actionPerformed(ActionEvent e)
            {
            if (inputReady && outputReady) {
            go();
            }
            }
            });

    guiPanel.add(inputBtn);
    guiPanel.add(inputLabel);
    guiPanel.add(new JSeparator(SwingConstants.HORIZONTAL));
    guiPanel.add(outputBtn);
    guiPanel.add(outputLabel);
    guiPanel.add(new JSeparator(SwingConstants.HORIZONTAL));
    guiPanel.add(goBtn);
    guiPanel.add(progressLabel);

    controlFrame.getContentPane().add(guiPanel, BorderLayout.WEST);
    controlFrame.pack();
    controlFrame.setVisible(true);
    controlFrame.setSize(700,200);
    controlFrame.setLocation(100,100);
    controlFrame.setResizable(false);
    controlFrame.requestFocus();
}


void processFile(File f) {
    String name = f.getName();
    String pattern = "(\\d\\d\\d\\d)(\\d\\d)(\\d\\d)_.*\\.jpg";
    Pattern r = Pattern.compile(pattern);

    // Now create matcher object.
    final SimpleDateFormat df = new SimpleDateFormat( "yyyy-MM-dd" );
    Matcher m = r.matcher(name);
    if (m.find()) {
        String sdate = "" + m.group(1) + "-" + m.group(2) + "-" + m.group(3);
        try {
            final Date dateTaken = df.parse( sdate ); // conversion from String
            addNewFileToProcess(f, dateTaken);
        } catch (ParseException ex) {
            System.out.println("Parse Exception: " + ex.toString());
        }
    } 
}

void addNewFileToProcess(File f, Date dateTaken)
{
    SchillerPic pic = new SchillerPic(f, dateTaken);
    picsToProcess.add(pic);
}

File getImageDirectory() {
    if (autoChoose) {
        return new File("/Users/JoeyMousepad/repos/SchillerEveryDay/before");
    }

    JFileChooser chooser = new JFileChooser();
    chooser.setCurrentDirectory(new java.io.File("."));
    chooser.setDialogTitle("Select Raw Image Directory Please...");
    chooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
    chooser.setAcceptAllFileFilterUsed(false);

    if (chooser.showOpenDialog(null) != JFileChooser.APPROVE_OPTION) {
        return null;
    }
    return chooser.getSelectedFile();
}

File getOutputDirectory() {
    if (autoChoose) {
        return new File("/Users/JoeyMousepad/repos/SchillerEveryDay/after");
    }

    JFileChooser chooser = new JFileChooser();
    chooser.setCurrentDirectory(new java.io.File("."));
    chooser.setDialogTitle("Select Output Directory Please...");
    chooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
    chooser.setAcceptAllFileFilterUsed(false);

    if (chooser.showOpenDialog(null) != JFileChooser.APPROVE_OPTION) {
        return null;
    }
    return chooser.getSelectedFile();
}

void setDefaultPaths() {
    inputDir = getImageDirectory();
    outputDir = getOutputDirectory();
    go();
}

void error(String errorMessage) {
    infoBox(errorMessage, "Error!");
    exit();
}

void infoBox(String infoMessage, String titleBar)
{
    JOptionPane.showMessageDialog(null, infoMessage, "InfoBox: " + titleBar, JOptionPane.INFORMATION_MESSAGE);
}

public class SchillerPic {
    public File inputFile;
    public Date dateTaken;
    public int picNumber; 
    public String outputString;
    public SchillerPic(File f, Date d) {
        inputFile = f;
        dateTaken = d;
        calcNumber();
        calcOutput();
    }

    private void calcNumber() {
        final String sdate = "2014-08-13"; // First picture date
        final SimpleDateFormat df = new SimpleDateFormat( "yyyy-MM-dd" );
        try {
            final Date date = df.parse( sdate ); // conversion from String

            long diffTime = dateTaken.getTime() - date.getTime();
            picNumber = (int)TimeUnit.DAYS.convert(diffTime, TimeUnit.MILLISECONDS) + 1;
        } catch (ParseException ex) {
            System.out.println("Parse Exception: " + ex.toString());
        }
    }

    private void calcOutput() {
        final SimpleDateFormat df = new SimpleDateFormat("MM_dd_yyyy");
        outputString = "SchillerPicADay.Number_" + String.format("%05d", picNumber) + ".Date_" + df.format(dateTaken) + ".jpg";
    }

    public String toString(){
        final SimpleDateFormat df = new SimpleDateFormat("MM.dd.yyyy");
        return "Pic #" + picNumber + ":\n\tDate Taken: " + df.format(dateTaken) + "\n\tInput File Path: " + inputFile.getAbsolutePath() + "\n\tOutput File Path: " + outputString;
    }
}

// Actually decorate the image
void addImageDecorations(SchillerPic pic) {
    drawBlackBars(pic);
    drawNumberOutlines(pic);
    drawText(pic);
}

int barHeight = 28;
void drawBlackBars(SchillerPic pic) {
    s.fill(0);
    fill(0);
    stroke(0);
    strokeWeight(1);
    s.stroke(0);
    s.strokeWeight(1);

    // Lower left
    zRect(-20, display.height-barHeight, 140, barHeight, 100);

    // Lower right
    zRect(display.width-107, display.height-barHeight, 190, barHeight, 100); // Days

    if (pic.picNumber > 365) {
        zRect(display.width-104, display.height-(barHeight*2), 190, barHeight, 100); // Years
    }
}

void drawText(SchillerPic pic) {
    textFont(f,20);
    s.textFont(f,20*ratio);

    // Date
    zFill(250);
    final SimpleDateFormat df = new SimpleDateFormat("MM/dd/yyyy");
    zText(df.format(pic.dateTaken),9,display.height-6); 

    // Year and Days Labels
    zFill(150);
    if (pic.picNumber > 365) {
        zText("Years:", display.width-98, display.height-barHeight-6);
    }
    zText("Days:", display.width-100, display.height-6);

    // Year and Days Numbers
    zFill(250);
    if (pic.picNumber > 365) {
        int displayYears = (((pic.picNumber-1) / 365));
        String sYears = "";
        if (displayYears < 10) {
            sYears = "  ";
        }
        zText(sYears + displayYears, display.width-29, display.height-barHeight-6); 
    }
    int displayNum = (((pic.picNumber-1) % 365) + 1);
    String sDays = "";
    int daysOffset = 40;
    if (displayNum < 10) {
        sDays = "    ";
    } else if (displayNum < 100) {
        sDays = "  ";
    }
    zText(sDays + displayNum, display.width-daysOffset, display.height-6); 
}

void zFill(int c) {
    fill(c);
    s.fill(c);
}


void zText(String t, int w, int h) {
    text(t,w,h);
    s.text(t,w*ratio,h*ratio);
}

void drawNumberOutlines(SchillerPic pic) {
    float strokeColor = 135;
    int zStrokeWeight = 2;
    s.noFill();
    s.stroke(strokeColor);
    s.strokeWeight(zStrokeWeight);
    noFill();
    stroke(strokeColor);
    strokeWeight(zStrokeWeight);

    int outlineWidth = 38;
    int outlineWidth2 = 29;
    int outlineHeight = 22;
    int diffInHeight = barHeight-outlineHeight;
    zRect(display.width-outlineWidth-5, display.height-outlineHeight-(diffInHeight/2), outlineWidth, outlineHeight, 8);

    if (pic.picNumber > 365) {
        zRect(display.width-outlineWidth2-5, display.height-outlineHeight-(diffInHeight/2)-barHeight, outlineWidth2, outlineHeight, 8);
    }
}

void zRect(int x, int y, int w, int h, int r) {
    rect(x,y,w,h,r);
    s.rect(x*ratio, y*ratio, w*ratio, h*ratio, r*ratio);
}

