package com.example.sheet_music_app

import android.util.Log
import com.example.sheet_music_app.pigeon.Length
import com.example.sheet_music_app.pigeon.Note
import com.example.sheet_music_app.pigeon.Pitch
import com.example.sheet_music_app.pigeon.ScannerAPI
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import org.opencv.android.OpenCVLoader
import org.opencv.core.Core
import org.opencv.core.Mat
import org.opencv.core.MatOfByte
import org.opencv.core.Point
import org.opencv.core.Scalar
import org.opencv.core.Size
import org.opencv.imgcodecs.Imgcodecs
import org.opencv.imgproc.Imgproc

//Class representing a Template Image - the actual image, and the note length
data class Template(val image: Mat, val length: Length)


//Loads the Template Assets and returns them as a list
fun loadTemplateAssets(activity: FlutterActivity): List<Template> {
    //Map of the file name to the note length
    val assets = mapOf(
        "template1.png" to Length.CROTCHET,
        "template2.jpg" to Length.MINIM
    )

    //Map over each of the items in the map, and load the image, returning an instance of the Template class
    return assets.map { item ->
        val key = FlutterInjector.instance().flutterLoader()
            .getLookupKeyForAsset("images/${item.key}")

        Template(activity.assets.openFd(key).use {
            val bytes = it.createInputStream().readBytes()
            val i = Imgcodecs.imdecode(MatOfByte(*bytes), Imgcodecs.IMREAD_ANYCOLOR)
            i
        }, item.value)
    }
}

//ScannerAPI implementation
class Scanner(private val activity: FlutterActivity) : ScannerAPI {
    //Scan image from given path, returning the path
    override fun scan(imagePath: String): List<Note> {
        //Setup OpenCV
        OpenCVLoader.initDebug()

//        //Get sheet music image key from assets to fetch the file
//        val key = FlutterInjector.instance().flutterLoader()
//            .getLookupKeyForAsset("images/sheet_music.jpg");
//
//
//        //Get the actual image from a stream of bytes
//        val img = activity.assets.openFd(key).use {
//            val bytes = it.createInputStream().readBytes()
//            Imgcodecs.imdecode(MatOfByte(*bytes), Imgcodecs.IMREAD_ANYCOLOR)
//        }

        //Load the templates
        var templates = loadTemplateAssets(activity)


        //Load image
        val img = Imgcodecs.imread(imagePath)

        //Preprocess Images
        preprocess(img)

        //Count the number of black pixels
        val blacks = countBlacks(img)

        //Find the 'peaks' of black
        val peaks = findPeaks(blacks)


        //Sort by how many black pixels there are in the row
        val stave = peaks.sortedByDescending { it.first }
            //Take the first 5
            .take(5)
            .map { it.second }.sorted()

        //Calculate Stave Height
        val staveHeight = calcStaveHeight(stave)
        Log.d("Stave Height", staveHeight.toString())
        Log.d("Original Template Size", templates.map { it.image.size() }.toString())

        //Resize templates to match stave height
        templates = templates.map { resize(it, staveHeight) }
        templates.forEach {
            preprocess(it.image)
        }


        Log.d("New Template Size", templates.map { it.image.size() }.toString())

        val points = templates.map {
            Pair(it, getPitches(img, it, stave))
        }

//
        //Change the image from greyscale to coloured
        Imgproc.cvtColor(img, img, Imgproc.COLOR_GRAY2RGB)
        //Draw a red line across the image for each
        stave.forEach {
            Imgproc.line(
                img,
                Point(0.0, it.toDouble()),
                Point(img.width().toDouble(), it.toDouble()),
                Scalar(
                    0.0,
                    0.0,
                    255.0,
                ),
                3
            )
        }
        val notes = points.map {
            it.second.sortedBy { it.second.y }.map { point ->
                Log.d("Note", point.first.toString())
                Log.d("Height", point.second.x.toString())
                Log.d(
                    "RelPitch",
                    kotlin.math.round((196 - point.second.x) * 2 / staveHeight).toString()
                )
                Pair(it.first, point)
            }
        }.flatten()
            .sortedBy { it.second.second.y }
            .map {
//                Log.d("Loc", it.second.toString())
//                Log.d("size", it.first.image.size().toString())
                Imgproc.circle(
                    img,
                    Point(it.second.second.y + 7, it.second.second.x - 7),
                    kotlin.math.max(it.first.image.width(), it.first.image.height()) / 2,
                    Scalar(0.0, 0.0, 255.0),
                    3
                )
                it.second.first
            }

        //Write image to disk
        Imgcodecs.imwrite(imagePath, img)

        //Return path of image
        return notes
    }

    //Required preprocessing on input images
    private fun preprocess(image: Mat) {
        //Convert to Greyscale
        Imgproc.cvtColor(image, image, Imgproc.COLOR_BGR2GRAY)

        //Make lighting uniform
//        val blur = Mat()
//        Imgproc.GaussianBlur(image, blur, Size(5.0, 5.0), 0.0)
//        Core.divide(image, blur, image, 255.0)

        //Binarize Image
//        Imgproc.threshold(image, image, 0.0, 255.0, Imgproc.THRESH_OTSU)
//        Core.bitwise_not(image, image)
        Imgproc.adaptiveThreshold(
            image,
            image,
            255.0,
            Imgproc.ADAPTIVE_THRESH_MEAN_C,
            Imgproc.THRESH_BINARY_INV,
            21,
            4.0
        )

        //Apply Morphological Close
        val strucElement2 = Imgproc.getStructuringElement(Imgproc.CV_SHAPE_ELLIPSE, Size(3.0, 3.0))
        Imgproc.morphologyEx(image, image, Imgproc.MORPH_OPEN, strucElement2)
//        val strucElement1 =
//            Imgproc.getStructuringElement(Imgproc.CV_SHAPE_ELLIPSE, Size(18.0, 15.0))
//        Imgproc.morphologyEx(image, image, Imgproc.MORPH_CLOSE, strucElement1)

        //Invert the image colours as they were inverted to be able to perform the close
        Core.bitwise_not(image, image)
    }


    //Return a list of the number of black pixels per row in an image
    private fun countBlacks(image: Mat): List<Int> {
        //The number of rows in the image
        val rows = image.rows()
        //The number of columns in the image
        val cols = image.cols()
        //The List keeping track of the number of black pixels per row
        //It is initialised with all zeroes and its length == number of rows
        val blacksPerRow = MutableList(rows) { 0 }
        //Iterate over the rows and columns
        for (row in 0 until rows) {
            for (col in 0 until cols) {
                //Pixel colour value - either [0.0] (black) or [255.0] (white)
                val pixel = image.get(row, col)
                //Increment row counter if current pixel is black
                if (pixel.contentEquals(doubleArrayOf(0.0))) {
                    blacksPerRow[row] += 1
                }
            }
        }
        return blacksPerRow
    }

    //Takes the data as a list and returns all the peaks in the form (value, index)
    private fun findPeaks(data: List<Int>): List<Pair<Int, Int>> {
        return when (data.size) {
            //No peaks in an empty list
            0 -> listOf()
            //Only element must be the only peak in a list of length 1
            1 -> listOf(Pair(data[0], 0))
            //Gets larger of 2 elements in list if only of length 2
            2 -> if (data[0] < data[1]) {
                listOf(Pair(data[1], 1))
            } else {
                listOf(Pair(data[0], 0))
            }

            else -> {
                //List storing peaks
                val peaks = mutableListOf<Pair<Int, Int>>()
                //Loop through list from index 2 to end
                for (i in 2 until data.size) {
                    val first = data[i - 2]
                    val second = data[i - 1]
                    val third = data[i]
                    //An element is only a peak if it is larger
                    //than the element before and after
                    if (first < second && third < second) {
                        peaks.add(Pair(second, i - 1))
                    }
                }
                //Return list of peaks
                peaks
            }
        }
    }

    //Takes the stave as a list and finds the average gap height for the stave
    private fun calcStaveHeight(stave: List<Int>): Double {
        val sortedStave = stave.sorted()
        var total = 0
        //For each gap in the stave, total the height
        for (i in 1 until sortedStave.size) {
            total += sortedStave[i] - sortedStave[i - 1]
        }
        return total.toDouble() / (sortedStave.size.toDouble() - 1.0)
    }

    private fun resize(template: Template, newHeight: Double): Template {
        val out = template.copy()
        val factor = (newHeight / template.image.size().height)
        Log.d("factor", factor.toString())
        Imgproc.resize(
            template.image,
            out.image,
            Size(0.0, 0.0),
            factor,
            factor
        )
        return out
    }

    //Given an image, the template image and the stave y-coordinates, return a list of the note values and their coordinate locations in the image.
    private fun getPitches(
        image: Mat,
        template: Template,
        stave: List<Int>
    ): List<Pair<Note, Point>> {
        //Perform template matching with the template image and the taken image
        val res = Mat()
        Imgproc.matchTemplate(image, template.image, res, Imgproc.TM_CCOEFF_NORMED)
        //Threshold for the image to be counted as correct
        val thresh = 0.55
        val rows = res.rows()
        val cols = res.cols()
        val matches = mutableListOf<Point>()
        //Add points to the matched list only if they are above the threshold
        for (row in 0 until rows) {
            for (col in 0 until cols) {
                val value = res.get(row, col)[0]
                if (value > thresh) {
                    matches.add(Point(row.toDouble(), col.toDouble()))
                }
            }
        }

        //Chunk together matches that overlap (to prevent the same note from being counted twice in case it is)
        val width = template.image.width()
        val height = template.image.height()
        //Each chunk is its own list of points representing matches that overlapped together
        val chunks = mutableListOf<MutableList<Point>>()

        outer@ for (i in matches) {
            for (j in 0 until chunks.size) {
                //If a match overlaps with any chunk, add it to that chunk
                val chunk = chunks[j][0]
                if (isOverlap(i, chunk, width, height)) {
                    chunks[j].add(i)
                    continue@outer
                }
            }
            //Otherwise add it to a new chunk
            chunks.add(mutableListOf(i))
        }
        return chunks.map {
            //average out the chunk position to get an estimate for the note's position
            val accPoint = it.fold(Point(0.0, 0.0)) { acc, point ->
                Point(acc.x + point.x, acc.y + point.y)
            }
            Point(accPoint.x / it.size, accPoint.y / it.size)

        }.map {
            //Offset the point to actually be the centre of the image
            Point(it.x + width / 2, it.y + height / 2)
        }.map {
            //Map each point to a pair of the pitch and its position
            Pair(posToPitch(it.x - 9, stave), it)
        }.map {
            //Map each pitch to a note
            Pair(Note(it.first, template.length), it.second)
        }
    }

    //Given 2 rectangles at points rect1 & rect2, return whether they overlap or not
    private fun isOverlap(rect1: Point, rect2: Point, width: Int, height: Int): Boolean {
        return rect1.x < rect2.x + width && rect2.x < rect1.x + width && rect1.y < rect2.y + height && rect2.y < rect1.y + height
    }

    //Given a height (y-coordinate) and the stave coordinates, calculate the pitch
    private fun posToPitch(height: Double, stave: List<Int>): Pitch {
        val staveHeight = calcStaveHeight(stave)
        //The note F5 is the zeroth line on the stave
        val F5 = stave[0]
        //Calculate the pitch as an offset from F5
        val relPitch = kotlin.math.round((F5 - height + 0.3) * 2 / staveHeight).toInt()
        //Calculate the pitch as F5 plus the offset
        return Pitch.ofRaw(Pitch.F5.raw + relPitch)!!
    }
}