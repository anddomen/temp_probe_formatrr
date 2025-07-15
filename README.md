# temp_probe_formatrr

This app and associated script is for collating multiple temperature probe .xlsx files into one. This is specifically for temperature probes set up using the EasyLog USB software. Our lab uses the EasyLog EL-USB-2-LCD style data loggers. Some of our probes can read relative humidity and dew point while others don't. This app can take any number of xlsx sheets from the probes and collates them, regardless if it is the type of probe that can read humidity or not.

**Important note:** When uploading multiple files, the script will identify the probe that was started last and make that zero across all probes. Probes with data that start before the last probe are assigned "negative minutes." This is so all probes are aligned. The original probe time is kept.

There is a standalone R Script that accomplishes this, but only on the probes that also read humidity and dew point (temp_probe_formatrr_nonGUI.R). I initially made this script as a starting point for the app.

I made the shiny app for my lab mates that either aren't comfortable with R or just don't want to mess with it. This will hopefully be a huge time saver for them and be kinder on their computers :)

**Example data that I used to develop the app is available in the Data folder.**

[**Link to app**](https://ahrouj-andrea0domen.shinyapps.io/temp_probe_formatrr/)

## How to use

### 1. Open the app

Either run the app.R script or visit the website. This is what you should see:

![](Screenshots/landing_page.png)

### 2. Upload your data

Using the dark blue upload box, click browse and highlight all of your temperature probe files to upload. These sheets should be the raw exports from EasyLog. 

![](Screenshots/upload_box.png)

![](Screenshots/file_selection.png)


When complete, a list of your files and their sizes will show and your data will automatically be collated. 


![](Screenshots/upload_done.png)


### 3. Check the stats

Once the interval is entered, the app will display the number of rows of the final collated file in addition to the average, min, and max temperatures of each probe, plus a graph of the data. Make sure this data makes sense!

![](Screenshots/file_stats.png)
![](Screenshots/probe_graph.png)

### 4. Download your data

If everything looks fine and dandy, use the final download box to give your collated file a name and click download. Note that if a probe that can't read relative humidity and dew point is used those cells will be blank in the final file.

![Ta da!](Screenshots/download.png)


