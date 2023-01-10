package com.goomsdk.view;

import android.content.Context;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.Color;
import android.graphics.Canvas;
import android.view.View;
import android.view.View.MeasureSpec;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import android.util.Log;

import androidx.constraintlayout.widget.ConstraintLayout;
//import androidx.percent layout.widget;

//import androidx.constraintlayout.widget.ConstraintLayout;

public class BasicVideoContainer extends FrameLayout {
    Paint fillPaint = new Paint();
    Paint strokePaint = new Paint();

    void initPaints() {

        // fill
        fillPaint.setStyle(Paint.Style.FILL);
        fillPaint.setColor(Color.BLACK);

        // stroke
        strokePaint.setStyle(Paint.Style.STROKE);
        strokePaint.setColor(Color.BLUE);
        strokePaint.setStrokeWidth(10);
    }

    public BasicVideoContainer(Context context) {
        super(context);
        initPaints();
    }

}
