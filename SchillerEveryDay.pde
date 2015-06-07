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

PImage source;
PImage display;

int displayWidth = 360;
int displayHeight = 640;

String outputDirectory = "";

ArrayList<SchillerPic> picsToProcess = new ArrayList<SchillerPic>();

// 
// Program starts here.
//
void setup() {

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
    if (processing) {

        if ((!onlyFirst && fileIndex < picsToProcess.size()) || (onlyFirst && fileIndex == 0)) {

            SchillerPic currentPic = picsToProcess.get(fileIndex);
            
            // Load image
            source = loadImage(currentPic.inputFile.getAbsolutePath());
            display = loadImage(currentPic.inputFile.getAbsolutePath());
            display.resize(displayWidth, displayHeight);

            // Show image
            image(display, 0, 0);

            String output = outputDir.getAbsolutePath() + "/" + currentPic.outputString;
            if (!autoChoose) {
                progressLabel.setText("  Status: Processing pic " + numFilesWritten + "/" + picsToProcess.size()); 
            }
            System.out.println("Saving File " + numFilesWritten++ + ": " + output);
            source.save(output);

            fileIndex++;

            if (onlyFirst) {
                noLoop();
            }
        } else {
            System.out.println("Done!");
            if (!autoChoose) {
                progressLabel.setText("  Status: Done!"); 
                fileIndex = 0;
                goBtn.setEnabled(true);
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
