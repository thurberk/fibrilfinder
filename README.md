# fibrilfinder
Software for locating amyloid fibrils or other helical structures on cryo-EM images, primarily designed for compatibility with RELION

Directions for use are in a paper to be published.

Automated picking of amyloid fibrils from cryo-EM images for helical reconstruction with RELION, Journal of Structural Biology
https://authors.elsevier.com/sd/article/S1047-8477(21)00041-1

Main files are:  

FibrilFinder_wMask.m   locates amyloid fibrils on cryo-EM images and outputs text files compatible with a RELION 3.1 ManualPick job.  Now allows use of an externally generated mask, such as from Micrograph Cleaner (Journal of Structural Biology 210 (2020) 107498)

FibrilFixer.m    removes particles (image boxes) that contain more than one amyloid fibril
