<a href="https://github.com/UCL"><img src="tools/logos/logo_UCL.png" alt="UCL Research Software Development" height="70"/></a>
<a href="https://www.ucl.ac.uk/biosciences/departments/genetics-evolution-and-environment/research/molecular-and-cultural-evolution-lab"><img src="tools/logos/logo_MACElab.png" alt="UCL Research Software Development" height="70"/></a>

# UCL RAP
## UCL Research Analysis Project

### Overview
Server automatically web scrapes keywords from UCL researcher profiles, analyses their frequency and similarities, generates wordclouds (for individuals, research groups and departments), and various summary statistics, graphics and timeseries of intra/inter group/departmental collaboration. Although this is a pilot project commissioned by UCL's Department of Genetics Evolution & Environment (GEE) Websites Review and Refresh Group 2020 chaired by Prof Mark Thomas, this is a legacy project providing value to everyone at UCL. Therefore collaboration and ideas are therefore most warmly welcomed. 

### Accessing and using wordclouds
Wordcloud images can be browsed in the 'wordclouds' folder, and directly embedded into any webpage (such as a departmental people page) using the github URL. Make sure to use the direct link to the raw file, not the URL in your browser.
For example, a direct link is https://github.com/UCL/RAP/raw/main/wordclouds/UPI/MMTIS18.png

Within the UCL content management system Drupal, this can be achieved as follows:
- log in to drupal to edit the required page
- insert a new image, using the Media Browser
- select the WEB tab
- paste in the direct link

This can also be achieved in html if preferred as follows:

```html
<a href="https://www.ucl.ac.uk"><img src="https://github.com/UCL/RAP/raw/main/wordclouds/UPI/MMTIS18.png"  height="200"/></a>
```

<a href="https://www.ucl.ac.uk"><img src="https://github.com/UCL/RAP/raw/main/wordclouds/UPI/MMTIS18.png"  height="200"/></a>

Word exclusions for a specific UPI can be placed in /tools/exclusions/individuals/\<UPI\>.txt

Unusual word changes can be specified by appending /tools/corrections/corrections.csv

### Current protocol
The Molecular And Cultural Evolution laboratory (MACE-lab) server regulary automatically webscrapes publications from UCL Discovery, generates wordclouds, summary statistics etc, for any UPI with 5 or more publications and for departments with more than 10 publications.
UCL comprises several hundred departments and tens of thousands of UPIs, making this process computationally costly. Therefore, only the least recently updated 200 UPIs and 10 departments are updated each day.

The following procedure is automatically performed nightly using scripts in the R folder:
- Web scrape Discovery to update  /tools/UPI/everyone.txt and /tools/departments/departments.txt
- Web scrape research keywords from IRIS and Discovery for researchers and keywords from Discovery for departments
- Combine keywords to form a frequency table for each UPI/group/department. Words from abstracts are weighted x1, titles are weighted x3, keywords are weighted x6, IRIS keywords are weighted x15.
- Various cleaning procedures, including truncation to the most frequent 350 words.
- Wordcloud images (.png) generated using wordcloud2 (R package) for each UPI and stored in the folder 'wordclouds'.
- Automated cropping using ImageMagick

### Future work
The following weekly summary plots/statistics are not yet implemented:
- Wordclouds for research groups.
- Distance matrix (each UPI and each group/department) based on keyword frequencies.
- Distance matrix (each UPI and each group/department) based on coauthorship.
- Connectivity trees (both in terms of similarity of research, and coauthorship).

### Contact
- Adrian Timpson: a.timpson@ucl.ac.uk
- Mark G Thomas: m.thomas@ucl.ac.uk
- Richard Mott: r.mott@ucl.ac.uk

---
