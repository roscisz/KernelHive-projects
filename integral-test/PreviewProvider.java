package pl.gda.pg.eti.kernelhive.gui.component.workflow.preview;

import java.awt.Color;
import java.awt.Graphics;
import java.lang.Math;
import java.util.List;
import pl.gda.pg.eti.kernelhive.common.monitoring.service.PreviewObject;

public class PreviewProvider implements IPreviewProvider {

    private static final int MAX_VALUE = 100;
	
    public void paintData(Graphics g, List<PreviewObject> data, int areaWidth, int areaHeight) {
        g.setColor(Color.YELLOW);
            
        float minX = Float.POSITIVE_INFINITY;
        float maxX = Float.NEGATIVE_INFINITY;
        float minY = 0;
        float maxY = Float.NEGATIVE_INFINITY;
            
        for(PreviewObject po : data) {
            if(validatePreviewObject(po)) {
                minX = Math.min(po.getF1(), minX);
                maxX = Math.max(po.getF1() + po.getF2(), maxX);
                maxY = Math.max(po.getF3(), maxY);
            }
        }
        float ratioX = areaWidth / (maxX - minX);
        float ratioY = areaHeight / (maxY - minY);
            
        for(PreviewObject po : data) {
            if(!validatePreviewObject(po)) {
                continue;
            }
            int width = Math.round(ratioX * po.getF2());
            int height = Math.round(ratioY * po.getF3());
            int x = Math.round(ratioX * po.getF1());
            int y = areaHeight - height;
            g.fillRect(x, y, width, height);
        }
    }

    private boolean validatePreviewObject(PreviewObject po) {
        return !Float.isNaN(po.getF1()) && Math.abs(po.getF1()) < MAX_VALUE
                && !Float.isNaN(po.getF2()) && Math.abs(po.getF2()) < MAX_VALUE
                && !Float.isNaN(po.getF3()) && Math.abs(po.getF3()) < MAX_VALUE;
    }
}