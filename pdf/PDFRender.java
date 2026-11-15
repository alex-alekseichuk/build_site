import java.io.IOException;
import java.io.FileNotFoundException;
import java.io.File;
import java.io.OutputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.FileInputStream;
import java.net.URL;

// these are for rendeing to image
import java.awt.image.BufferedImage;
import javax.imageio.ImageIO;
import org.xhtmlrenderer.swing.Java2DRenderer;
import org.xhtmlrenderer.simple.ImageRenderer;
import org.xhtmlrenderer.simple.Graphics2DRenderer;
import org.xhtmlrenderer.util.FSImageWriter;

import org.xhtmlrenderer.pdf.ITextRenderer;
import org.xhtmlrenderer.pdf.ITextUserAgent;
import org.xhtmlrenderer.pdf.ITextFSImage;
import org.xhtmlrenderer.resource.CSSResource;
import org.xhtmlrenderer.resource.ImageResource;
import org.xhtmlrenderer.context.StyleReference;
import org.xhtmlrenderer.layout.SharedContext;

import com.lowagie.text.BadElementException;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Image;

public class PDFRender {
    public static void main(String[] args) throws IOException, DocumentException {
        if (args.length < 2 || args.length > 3) {
            System.err.println("Usage: ... url pdf [png]");
            System.exit(1);
        }
        String url = args[0];
		String url2 = url;
		String pdf = args[1];
        if (url.indexOf("://") == -1) {
            // maybe it's a file
            File f = new File(url);
            if (f.exists()) {
                url2 = f.toURI().toURL().toString();
            }
        }

        createPDF(url2, pdf);

		if (args.length > 2)
		{
			String png = args[2];
			if (png.equals("-"))
			{
				String path = pdf;
				path = path.substring(0, path.lastIndexOf("."));
				png = path + ".png";
			}
			createPNG(url, png);
		}

		System.exit(0);
    }

	protected static void createPNG(String xhtml, String png)
		throws IOException, DocumentException 
	{
		File f = new File(xhtml);
		int width = 800;
		int height = 1024;

		Java2DRenderer renderer = new Java2DRenderer(f, 300);
		renderer.setBufferedImageType(BufferedImage.TYPE_INT_RGB);

		BufferedImage image = renderer.getImage();

		FSImageWriter imageWriter = new FSImageWriter();
		imageWriter.write(image, png);

	}

    protected static void createPDF(String url, String pdf)
            throws IOException, DocumentException {
        OutputStream os = null;
        try {
            os = new FileOutputStream(pdf);

            ITextRenderer renderer = new ITextRenderer();

            renderer.setDocument(url);
            renderer.layout();
            renderer.createPDF(os);

            os.close();
            os = null;
        } finally {
            if (os != null) {
                try {
                    os.close();
                } catch (IOException e) {
                    // ignore
                }
            }
        }
    }
}
