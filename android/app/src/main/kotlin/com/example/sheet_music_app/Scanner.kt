package com.example.sheet_music_app

import com.example.sheet_music_app.pigeon.ScannerAPI
import org.opencv.android.OpenCVLoader
import org.opencv.imgcodecs.Imgcodecs
import org.opencv.imgproc.Imgproc

//ScannerAPI implementation
class Scanner : ScannerAPI {
    //Scan image from given path, returning the path
    override fun scan(imagePath: String): String {
        //Setup OpenCV
        OpenCVLoader.initDebug()
        //Load image
        val img = Imgcodecs.imread(imagePath)
        //Change image colour to greyscale
        Imgproc.cvtColor(img, img, Imgproc.COLOR_BGR2GRAY)
        //Write image to disk
        Imgcodecs.imwrite(imagePath, img)
        //Return path of image
        return imagePath
    }
}