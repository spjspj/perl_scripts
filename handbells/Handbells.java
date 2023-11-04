package com.otique.handbell2020;

import android.app.AlertDialog;
import android.app.Dialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.res.Configuration;
import android.graphics.Canvas;
import android.graphics.DashPathEffect;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.Point;
import android.graphics.PointF;
import android.graphics.Rect;
import android.graphics.RectF;
import android.graphics.Region;
import android.media.MediaPlayer;
import android.os.Environment;
import android.os.Parcel;
import android.os.Parcelable;
import android.util.AttributeSet;
import android.util.DisplayMetrics;
import android.view.Display;
import android.view.GestureDetector;
import android.view.MotionEvent;
import android.view.ScaleGestureDetector;
import android.widget.OverScroller;

import androidx.core.os.ParcelableCompat;
import androidx.core.os.ParcelableCompatCreatorCallbacks;
import androidx.core.view.GestureDetectorCompat;
import androidx.core.view.ViewCompat;
import androidx.core.widget.EdgeEffectCompat;

import java.io.File;
import java.io.FileWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Random;
import java.util.Timer;
import java.util.TimerTask;

public class HandBells extends android.view.View
{
    double [] bell_center_x = null;
    double [] bell_center_y = null;
    boolean [] bell_hand_or_back_stroke = null;
    boolean on_hand_stroke = true;
    boolean in_handbell_gap = false;
    int STARTING_PAST = 8;
    int num_nostuff_ups = 0;
    int num_stuff_ups = 0;
    int num_recent_stuff_ups = 0;
    int num_stuff_ups_to_show_help_at = 8;
    int past = STARTING_PAST;
    int timer_counter = 0;
    private EdgeEffectCompat mEdgeEffectBottom;
    private EdgeEffectCompat mEdgeEffectLeft;
    private EdgeEffectCompat mEdgeEffectRight;
    private EdgeEffectCompat mEdgeEffectTop;
    private GestureDetectorCompat mGestureDetector;
    private OverScroller mScroller;
    private Paint control_paint;
    private Paint mActiveComputerBellPaint;
    private Paint mDataPaint2;
    private Paint mGridPaint;
    private Paint mInactiveComputerBellPaint;
    private Paint mInverseInactiveComputerBellPaint;
    private Paint mInactiveUserBellPaint;
    private Paint mLabelTextPaint;
    private Paint mInfoTextPaint;
    private Paint mSelectedPaint;
    private Paint mUserBellPaint;
    private Paint sel_control_paint;
    private Point mSurfaceSizeBuffer = new Point();
    private PointF mZoomFocalPoint = new PointF();
    private RectF mScrollerStartViewport = new RectF(); // Used only for zooms and flings.
    private ScaleGestureDetector mScaleGestureDetector;
    private String CURRENTLY_RINGING_STR = "";
    private String CURRENT_CALL = "";
    private String OLD_CALL = "";
    private String OLD_CALL2 = "";
    private String OLD_CALL3 = "";
    private String OLD_CALL4 = "";
    private String method_str = "";
    private Zoomer mZoomer;
    private boolean mEdgeEffectBottomActive;
    private boolean mEdgeEffectLeftActive;
    private boolean mEdgeEffectRightActive;
    private boolean mEdgeEffectTopActive;
    private boolean selected_pause = false;
    private float mAxisThickness;
    private float mDataThickness;
    private float mGridThickness;
    private float mLabelTextSize;
    private float mInfoTextSize;
    private int CURRENT_BELL_HIT = -1;
    private int mAxisColor;
    private int mDataColor;
    private int mGridColor;
    private int mLabelHeight;
    private int mLabelSeparation;
    private int mLabelTextColor;
    private int mMaxLabelWidth;
    private static final float AXIS_X_MAX = 1f;
    private static final float AXIS_X_MIN = -1f;
    private static final float AXIS_Y_MAX = 1f;
    private static final float AXIS_Y_MIN = -1f;
    private RectF mCurrentViewport = new RectF(AXIS_X_MIN, AXIS_Y_MIN, AXIS_X_MAX, AXIS_Y_MAX);
    private static final float PAN_VELOCITY_FACTOR = 2f;
    private static final float ZOOM_AMOUNT = 0.25f;
    private static final int DRAW_STEPS = 70;
    public Rect mContentRect = new Rect();
    public Rect max_rect = new Rect();
    static public boolean allow_swiping = true;
    static public boolean show_controls = true;
    static public int bell_position_ringing_now = 1;
    static public int chosen_bell = -1;
    static public int second_chosen_bell = -1;

    public HandBells(Context context)
    {
        this(context, null, 0);
    }
    public HandBells(Context context, AttributeSet attrs)
    {
        this(context, attrs, 0);
    }
    public HandBells(Context context, AttributeSet attrs, int defStyle)
    {
        super(context, attrs, defStyle);
        //System.out.println ("public BlueLine(Context " + context+". AttributeSet " + attrs+". int " + defStyle+".) ");
        mLabelTextColor = 1;
        mLabelTextSize = 96;
        mInfoTextSize = 48;
        mLabelSeparation = 12;
        mGridThickness = 4;
        mGridColor = 4;
        mAxisThickness = 4;
        mAxisColor = 2;
        mDataThickness = 3;
        mDataColor = 3;
        initPaints();
        initSounds(context);
        mScaleGestureDetector = new ScaleGestureDetector(context, mScaleGestureListener);
        mGestureDetector = new GestureDetectorCompat(context, mGestureListener);
        mScroller = new OverScroller(context);
        mZoomer = new Zoomer(context);
        mEdgeEffectLeft = new EdgeEffectCompat(context);
        mEdgeEffectTop = new EdgeEffectCompat(context);
        mEdgeEffectRight = new EdgeEffectCompat(context);
        mEdgeEffectBottom = new EdgeEffectCompat(context);
    }


    MediaPlayer bell1 = null;
    MediaPlayer bell2 = null;
    MediaPlayer bell3 = null;
    MediaPlayer bell4 = null;
    MediaPlayer bell5 = null;
    MediaPlayer bell6 = null;
    MediaPlayer bell7 = null;
    MediaPlayer bell8 = null;

    private void initSounds(Context context)
    {
        bell1 = MediaPlayer.create (context, R.raw.bell1);
        bell2 = MediaPlayer.create (context, R.raw.bell2);
        bell3 = MediaPlayer.create (context, R.raw.bell3);
        bell4 = MediaPlayer.create (context, R.raw.bell4);
        bell5 = MediaPlayer.create (context, R.raw.bell5);
        bell6 = MediaPlayer.create (context, R.raw.bell6);
        bell7 = MediaPlayer.create (context, R.raw.bell7);
        bell8 = MediaPlayer.create (context, R.raw.bell8);
    }


    private void initPaints()
    {
        //System.out.println ("private void initPaints() ");
        mLabelTextPaint = new Paint();
        mLabelTextPaint.setAntiAlias(true);
        mLabelTextPaint.setTextSize(mLabelTextSize);
        mLabelTextPaint.setColor (0xffffAAAA);
        mLabelHeight = (int) Math.abs(mLabelTextPaint.getFontMetrics().top);
        mMaxLabelWidth = (int) mLabelTextPaint.measureText("0000");
        mInfoTextPaint = new Paint();
        mInfoTextPaint.setAntiAlias(true);
        mInfoTextPaint.setTextSize(mInfoTextSize);
        mInfoTextPaint.setColor (0xffffAAAA);
        mLabelHeight = (int) Math.abs(mInfoTextPaint.getFontMetrics().top);
        mMaxLabelWidth = (int) mInfoTextPaint.measureText("0000");
        mGridPaint = new Paint();
        mGridPaint.setStrokeWidth(5);
        mGridPaint.setColor(0xFFeeeeee);
        mGridPaint.setStyle(Paint.Style.FILL);
        mSelectedPaint = new Paint();
        mSelectedPaint.setStrokeWidth(mGridThickness);
        mSelectedPaint.setColor(0xFFaaaaff);
        mSelectedPaint.setStyle(Paint.Style.FILL);
        mUserBellPaint = new Paint();
        mUserBellPaint.setStrokeWidth(mAxisThickness);
        mUserBellPaint.setColor(0xFFA050A0);
        mUserBellPaint.setStyle(Paint.Style.FILL);
        mInactiveUserBellPaint = new Paint();
        mInactiveUserBellPaint.setStrokeWidth(mAxisThickness);
        mInactiveUserBellPaint.setColor(0xFF009900);
        mInactiveUserBellPaint.setStyle(Paint.Style.FILL);
        mActiveComputerBellPaint = new Paint();
        mActiveComputerBellPaint.setStrokeWidth(mAxisThickness);
        mActiveComputerBellPaint.setColor(0xFF8080C0);
        mActiveComputerBellPaint.setStyle(Paint.Style.FILL);

        mInactiveComputerBellPaint = new Paint();
        mInactiveComputerBellPaint.setStrokeWidth(mAxisThickness);
        mInactiveComputerBellPaint.setColor(0xFFDDDDDD);
        mInactiveComputerBellPaint.setStyle(Paint.Style.FILL);

        mInverseInactiveComputerBellPaint = new Paint();
        mInverseInactiveComputerBellPaint.setStrokeWidth(mAxisThickness);
        mInverseInactiveComputerBellPaint.setColor(0xFF888888);
        mInverseInactiveComputerBellPaint.setStyle(Paint.Style.FILL);
        //aarrggbb
        mDataPaint2 = new Paint();
        mDataPaint2.setStrokeWidth(mDataThickness);
        mDataPaint2.setColor(0xff0000ff);
        mDataPaint2.setStyle(Paint.Style.STROKE);
        mDataPaint2.setPathEffect (new DashPathEffect(new float[] {10,10}, 0));
        mDataPaint2.setAntiAlias(true);
        control_paint = new Paint();
        control_paint.setStrokeWidth (2);
        control_paint.setColor (0xff88FF88);
        control_paint.setStyle (Paint.Style.FILL_AND_STROKE);
        control_paint.setAntiAlias (true);
        sel_control_paint = new Paint();
        sel_control_paint.setStrokeWidth (2);
        sel_control_paint.setColor (0xffbbbbff);
        sel_control_paint.setStyle (Paint.Style.FILL_AND_STROKE);
        sel_control_paint.setAntiAlias (true);
    }
    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh)
    {
        DisplayMetrics displaymetrics = new DisplayMetrics();
        MultiBell.t.getWindowManager().getDefaultDisplay().getMetrics(displaymetrics);
        int height = displaymetrics.heightPixels;
        int width = displaymetrics.widthPixels;
        super.onSizeChanged  (width, height, w, h);
        if (getResources().getConfiguration().orientation == Configuration.ORIENTATION_LANDSCAPE)
        {
            set_size (height, width);
        }
        else
        {
            set_size (height, width);
        }
        //System.out.println ("protected void onSizeChanged(int " + w+". int " + h+". int " + oldw+". int " + oldh+". ) ");
    }

    public void set_size (int h, int w)
    {
        mContentRect.set(
            getPaddingLeft(), // + mMaxLabelWidth + mLabelSeparation,
            getPaddingTop(),
            w - getPaddingRight(),
            h - getPaddingBottom() - mLabelHeight - mLabelSeparation - 100);
        max_rect.set(8, 8, Math.max (h, w), Math.max (h, w));
    }
    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec)
    {

        DisplayMetrics displaymetrics = new DisplayMetrics();
        Display d = MultiBell.t.getWindowManager().getDefaultDisplay();
        MultiBell.t.getWindowManager().getDefaultDisplay().getMetrics(displaymetrics);
        int height = displaymetrics.heightPixels - 200;
        int width = displaymetrics.widthPixels;

        //System.out.println ("protected void onMeasure(int " + widthMeasureSpec+". int " + heightMeasureSpec+". ) ");
        if (getResources().getConfiguration().orientation == Configuration.ORIENTATION_LANDSCAPE)
        {
            setMeasuredDimension (width, height);
        }
        else
        {
            setMeasuredDimension (width, height);
        }
        int h = getMeasuredHeight();
        int w = getMeasuredWidth();
        w = h + w;
    }
    @Override
    protected void onDraw(Canvas canvas)
    {
        canvas.clipRect(max_rect, Region.Op.REPLACE);
        drawDataSeriesUnclipped(canvas);
        canvas.drawRect(mContentRect, mDataPaint2);
    }
    int TOP = 20;
    int DOUBLE_SIZE = 60;
    int SIZE = 30;
    int WIDTH = 10;
    int DOUBLE_WIDTH = 15;
    int GAP = 5;
    private void drawTriangle (Canvas canvas, Point a, Point b, Point c, boolean bb)
    {
        if (a == null || b == null || c == null) { return; }
        Path path = new Path ();
        path.setFillType (Path.FillType.EVEN_ODD);
        path.moveTo (a.x, a.y);
        path.lineTo (b.x, b.y);
        path.lineTo (c.x, c.y);
        path.lineTo (a.x, a.y);
        path.close ();
        if (bb)
        {
            canvas.drawPath(path, sel_control_paint);
        }
        else
        {
            canvas.drawPath(path, control_paint);
        }
    }
    private void drawRectangle (Canvas canvas, Point a, Point b, Point c, Point d, boolean bb)
    {
        if (a == null || b == null || c == null || d == null) { return; }
        Path path = new Path ();
        path.setFillType (Path.FillType.EVEN_ODD);
        path.moveTo (a.x, a.y);
        path.lineTo (b.x, b.y);
        path.lineTo (c.x, c.y);
        path.lineTo (d.x, d.y);
        path.lineTo (a.x, a.y);
        path.close ();
        if (bb)
        {
            canvas.drawPath(path, sel_control_paint);
        }
        else
        {
            canvas.drawPath(path, control_paint);
        }
    }
    private void drawControls(Canvas canvas)
    {
    }
    int number_bells = 1;
    float bell_grid = 0;
    float current_view_top = 0;
    boolean setup_initial_params = true;

    private void init_params ()
    {
        bell_center_x = null;
        bell_center_y = null;
        bell_hand_or_back_stroke = null;
        num_stuff_ups = 0;
        num_nostuff_ups = 0;
        TOTAL_TIMER_COUNTER = 0;
        method_str = "";
        number_bells = (strs.get (0).length () - 3) / 2;
        bell_grid = (mContentRect.right - mContentRect.left) / (number_bells);
        current_view_top = ((mCurrentViewport.top + 1) / 2) * mContentRect.height() + mContentRect.top;

        if (chosen_bell == -1 || chosen_bell < 1 || chosen_bell > number_bells)
        {
            Random rn = new Random();
            int range = number_bells - 2 + 1;

            if (number_bells % 2 == 0) {
                // Ensure pairs like 1,2  3,4  5,6  7,8..
                chosen_bell = rn.nextInt (number_bells / 2) * 2 + 1;
                second_chosen_bell = chosen_bell + 1;
            } else {
                // can be any two??
                chosen_bell = rn.nextInt (number_bells) + 1;
                second_chosen_bell = chosen_bell + 1;
            }

            if (second_chosen_bell > number_bells)
            {
                second_chosen_bell --;
                chosen_bell --;
            }
        }
    }

    boolean ok_to_get_user_input = false;
    static public int delay = 18;
    static public int ORIGINAL_DELAY = 18;
    int num_correct_rings = 0;
    boolean same_trigger_pulled = false;
    static public int USER_BELL_RADIUS = 120;
    private void set_clicked_bell (float x, float y)
    {
        // Stop multiple hits??
        int new_pressed_bell = calc_bell (x, y);
        if (CURRENT_BELL_HIT != -1)
        {
            //System.out.println("Setting (NOT SETTING) due to multi clicks:" + new_pressed_bell + "  currently " + CURRENT_BELL_HIT + " >>> " + TOTAL_TIMER_COUNTER);
            return;
        }
        CURRENT_BELL_HIT = calc_bell (x, y);
        //System.out.println("Setting current bell to be:" + CURRENT_BELL_HIT + " >>> " + TOTAL_TIMER_COUNTER);
        // Check if the new bell is actually going to be correct...
        if (CURRENT_BELL_HIT != -1)
        {
            //System.out.println("Forcing redraw!!:" + CURRENT_BELL_HIT);
            force_redraw();
        }
    }

    private int calc_bell (float x, float y)
    {
        if (bell_center_x != null && bell_center_y != null)
        {
            if (chosen_bell != -1 && second_chosen_bell != -1)
            {
                if (   Math.abs (x - bell_center_x [chosen_bell]) < USER_BELL_RADIUS
                    && Math.abs (y - bell_center_y [chosen_bell]) < USER_BELL_RADIUS)
                {
                    return chosen_bell;
                }
                if (   Math.abs (x - bell_center_x [second_chosen_bell]) < USER_BELL_RADIUS
                    && Math.abs (y - bell_center_y [second_chosen_bell]) < USER_BELL_RADIUS)
                {
                    return second_chosen_bell;
                }
            }
        }
        return -1;
    }


    private void adjust_delay (int up_or_down)
    {
        if (up_or_down == 1)
        {
            //delay ++;
            if (delay > ORIGINAL_DELAY * 2)
            {
                //delay --;
            }
        }
        if (up_or_down == -1)
        {
            //delay --;
            if (delay < ORIGINAL_DELAY)
            {
                //delay ++;
            }
        }
    }

    private void drawDataSeriesUnclipped (Canvas canvas)
    {
        if (strs == null)
        {
            currently_ringing = false;
            return;
        }

        //System.out.println("Doing timer_counter of:" + timer_counter);
        if (setup_initial_params)
        {
            setup_initial_params = false;
            init_params ();
        }
        // 'c: 1 2 3 4 5 6 '
        int bell_index = 1;
        if (bell_center_x == null)
        {
            bell_center_x = new double [number_bells + 1];
            bell_center_y = new double [number_bells + 1];
            bell_hand_or_back_stroke = new boolean [number_bells + 1];
        }
        float [] selected_line = new float [4];

        if (past > strs.size () - STARTING_PAST)
        {
            past = STARTING_PAST;
            strs = null;
            setup_initial_params = false;
            return;
        }
        int b;

        int info_y = 55550;
        int info_x = 0;
        int center_x = (mContentRect.right - mContentRect.left) / 2;
        int center_y = (mContentRect.top - mContentRect.bottom) / 2;
        if (center_x < 0) { center_x *= -1; }
        if (center_y < 0) { center_y *= -1; }
        int radius = center_x - 120;
        if (center_y - 120 < radius)
        {
            radius = center_y - 120;
        }
        if (center_y < 0) { center_y *= -1; }
        double angle_between = 2 * Math.PI / number_bells;

        ///         3*pi/2
        //           |
        ///  pi <----+----> 0
        //           |
        ///         pi/2
        double current_angle = Math.PI / 2 - (angle_between / 2) - (chosen_bell - 1) * angle_between;
        String the_method = "";

        for (b = 1; b <= number_bells; b++)
        {
            bell_center_x [b] = center_x + radius * Math.cos(current_angle);
            bell_center_y [b] = center_y + radius * Math.sin(current_angle);
            current_angle += angle_between;
            if (bell_center_y[b] < info_y) {
                info_y = (int) bell_center_y[b] - 200;
                info_x = 0;
            }

            int bell_ringing_now = get_bell_row_position (bell_position_ringing_now);
            bell_hand_or_back_stroke [bell_ringing_now] = on_hand_stroke;
            String text = "";
            int x = (int)bell_center_x[b];
            int y = (int)bell_center_y[b];
            Paint paint = mInactiveComputerBellPaint;
            text = "" + b;

            if (CURRENT_BELL_HIT != -1)
            {
                // Success
                //System.out.println ("BRN=" + bell_ringing_now + " CBH=" + CURRENT_BELL_HIT + " b=" + b);

                if (CURRENT_BELL_HIT == b && b == bell_ringing_now && (b == chosen_bell || b == second_chosen_bell))
                {
                    text = "YAY";
                    num_nostuff_ups ++;
                    num_stuff_ups --;
                    num_recent_stuff_ups --;
                    if (num_recent_stuff_ups < 0)
                    {
                        num_recent_stuff_ups = 0;
                        adjust_delay (-1);
                    }

                    paint = mUserBellPaint;
                    //System.out.println (bell_ringing_now + ":BELLHIT:" + "Found chosen valid bell hit of " + CURRENT_BELL_HIT);
                }
                // Validly silent as other bell ringing
                else if (CURRENT_BELL_HIT != b && b != bell_ringing_now && (b == chosen_bell || b == second_chosen_bell))
                {
                    paint = mInactiveUserBellPaint;
                    //System.out.println (bell_ringing_now + ":BELLHIT:" + " Valid other user bell ringing " + CURRENT_BELL_HIT);
                }
                // Missed chosen
                else if (CURRENT_BELL_HIT != bell_ringing_now && b == chosen_bell)
                {
                    paint = mInactiveUserBellPaint;
                    text = "Missed!" + b;
                    num_stuff_ups ++;
                    num_recent_stuff_ups ++;
                    if (num_recent_stuff_ups > 5)
                    {
                        num_recent_stuff_ups = 0;
                        adjust_delay (1);
                    }
                    //System.out.println (bell_ringing_now + ":BELLHIT:" + " MISSED IT: " + b);
                }
                // Missed second_chosen
                else if (CURRENT_BELL_HIT != bell_ringing_now && b == second_chosen_bell)
                {
                    paint = mInactiveUserBellPaint;
                    text = "WrongBell!" + b;
                    num_stuff_ups ++;
                    num_recent_stuff_ups ++;
                    if (num_recent_stuff_ups > 5)
                    {
                        num_recent_stuff_ups = 0;
                        adjust_delay (1);
                    }
                    //System.out.println (bell_ringing_now + ":BELLHIT:" + " MISSED IT 2: " + b);
                }
                // Clash with computer bell
                else if (b == bell_ringing_now)
                {
                    text = "Clash:" + b;
                    paint = mActiveComputerBellPaint;
                    num_stuff_ups ++;
                    num_recent_stuff_ups ++;
                    if (num_recent_stuff_ups > 5)
                    {
                        num_recent_stuff_ups = 0;
                        adjust_delay (1);
                    }
                    //System.out.println (bell_ringing_now + ":BELLHIT:" + "Clash of " + CURRENT_BELL_HIT + " with bell: " + b);
                }
                else if (b != chosen_bell && b != second_chosen_bell && b != bell_ringing_now)
                {
                    paint = mInactiveComputerBellPaint;
                    if (bell_hand_or_back_stroke [b])
                    {
                        paint = mInverseInactiveComputerBellPaint;
                    }
                    //System.out.println (bell_ringing_now + ":BELLHIT:" + "Inactive bell: " + b);
                }
            }
            // Missed the ring
            else if (b == bell_ringing_now && (b == chosen_bell || b == second_chosen_bell))
            {
                paint = mInactiveUserBellPaint;
                text = "Missed:" + b;
                num_stuff_ups ++;
                num_recent_stuff_ups ++;
                if (num_recent_stuff_ups > 5)
                {
                    num_recent_stuff_ups = 0;
                    adjust_delay (1);
                }
                //System.out.println (bell_ringing_now + ":" + "NNN: Missed user  bell: " + b);
            }
            else if (b == chosen_bell || b == second_chosen_bell)
            {
                paint = mInactiveUserBellPaint;
                text = "" + b;
                //System.out.println (bell_ringing_now + ":" + "NNN: Inactive user  bell: " + b);
            }
            else if (b == bell_ringing_now && b != chosen_bell && b != second_chosen_bell)
            {
                paint = mActiveComputerBellPaint;
                //System.out.println (bell_ringing_now + ":" + "NNN: Active computer bell: " + b);
            }
            else
            {
                paint = mInactiveComputerBellPaint;
                if (bell_hand_or_back_stroke [b])
                {
                    paint = mInverseInactiveComputerBellPaint;
                }
                //System.out.println (bell_ringing_now + ":" + "NNN: Inactive computer  bell: " + b);
            }

            /*
            if (!(bell_ringing_now == chosen_bell || bell_ringing_now == second_chosen_bell))
            {
                if (bell_ringing_now == 1) { bell1.start(); }
                if (bell_ringing_now == 2) { bell2.start(); }
                if (bell_ringing_now == 3) { bell3.start(); }
                if (bell_ringing_now == 4) { bell4.start(); }
                if (bell_ringing_now == 5) { bell5.start(); }
                if (bell_ringing_now == 6) { bell6.start(); }
                if (bell_ringing_now == 7) { bell7.start(); }
                if (bell_ringing_now == 8) { bell8.start(); }
            }

            if (CURRENT_BELL_HIT != -1)
            {
                if (CURRENT_BELL_HIT == 1) { bell1.start(); }
                if (CURRENT_BELL_HIT == 2) { bell2.start(); }
                if (CURRENT_BELL_HIT == 3) { bell3.start(); }
                if (CURRENT_BELL_HIT == 4) { bell4.start(); }
                if (CURRENT_BELL_HIT == 5) { bell5.start(); }
                if (CURRENT_BELL_HIT == 6) { bell6.start(); }
                if (CURRENT_BELL_HIT == 7) { bell7.start(); }
                if (CURRENT_BELL_HIT == 8) { bell8.start(); }
            }
             */

            canvas.drawCircle(x, y, USER_BELL_RADIUS, paint);

            if (bell_hand_or_back_stroke [b])
            {
                canvas.drawLine(x, y, x + 30, y - 30, mGridPaint);
            }
            else
            {
                canvas.drawLine(x, y, x + 30, y, mGridPaint);
            }


            bell_hand_or_back_stroke [bell_ringing_now] = on_hand_stroke;
            canvas.drawText(text, x - 70, y + 35, mLabelTextPaint);

            bell_index++;
        }


        // Draw   * * * 1 * * 2 * near the center..
        double centerline_x = center_x - 0.6 * radius;
        double centerline_y = center_y;
        double to_add_x = 1.2 * radius / (number_bells - 1);

        // Draw the call in the center!
        if (CURRENT_CALL.matches (".*!"))
        {
            //canvas.drawText(CURRENT_CALL, (int) centerline_x, (int) centerline_y, mInfoTextPaint);
            OLD_CALL = CURRENT_CALL;
            CURRENT_CALL = "";
        }
        
        if (OLD_CALL.matches (".*!")) { OLD_CALL2 = OLD_CALL; OLD_CALL = ""; }
        else if (OLD_CALL2.matches (".*!")) { canvas.drawText(OLD_CALL2, (int) centerline_x, (int) centerline_y, mInfoTextPaint); OLD_CALL3 = OLD_CALL2; OLD_CALL2 = ""; }
        else if (OLD_CALL3.matches (".*!")) { canvas.drawText(OLD_CALL3, (int) centerline_x, (int) centerline_y, mInfoTextPaint); OLD_CALL4 = OLD_CALL3; OLD_CALL3 = ""; }
        else if (OLD_CALL4.matches (".*!")) { canvas.drawText(OLD_CALL4, (int) centerline_x, (int) centerline_y, mInfoTextPaint); OLD_CALL4 = ""; }


        for (int ci = 1; ci <= number_bells && num_stuff_ups >= num_stuff_ups_to_show_help_at; ci++)
        {
            //num_stuff_ups_to_show_help_at += 4;
            int bell_at = get_bell_row_position (ci);
            if (bell_at == chosen_bell || bell_at == second_chosen_bell)
            {
                canvas.drawCircle((int) centerline_x, (int) centerline_y, (int) (USER_BELL_RADIUS * 0.15), mInfoTextPaint);
            }
            else
            {
                if (bell_at == 1)
                {
                    canvas.drawCircle((int) centerline_x, (int) centerline_y, (int) (USER_BELL_RADIUS * 0.1), mLabelTextPaint);
                }
                else
                {
                    canvas.drawCircle((int) centerline_x, (int) centerline_y, (int) (USER_BELL_RADIUS * 0.1), mInactiveComputerBellPaint);
                }
            }

            if (ci == bell_position_ringing_now)
            {
                canvas.drawCircle((int) centerline_x, (int) centerline_y, (int) (USER_BELL_RADIUS * 0.12), mActiveComputerBellPaint);
            }

            if (bell_at == chosen_bell || bell_at == second_chosen_bell)
            {
                String text = "" + bell_at;
                canvas.drawText(text, (int) centerline_x, (int) centerline_y, mLabelTextPaint);
            }
            centerline_x += to_add_x;
        }

        if (num_stuff_ups > num_stuff_ups_to_show_help_at)
        {
            num_stuff_ups_to_show_help_at --;
            if (num_stuff_ups_to_show_help_at < 8)
            {
                num_stuff_ups_to_show_help_at = 8;
            }
        }

        if (CURRENT_BELL_HIT != -1) {
            //System.out.println("Set current bell hit from: " + CURRENT_BELL_HIT + " to -1");
            CURRENT_BELL_HIT = -1;
        }

        if (past < strs.size ())
        {
            canvas.drawText(CURRENTLY_RINGING_STR + " Change:" + past + " Good=" + num_nostuff_ups + " Bad=" + num_stuff_ups, info_x, info_y, mInfoTextPaint);
            //System.out.println(CURRENTLY_RINGING_STR);
        }

        if (method_str.equalsIgnoreCase(""))
        {
            for (int i = 0; i < strs.size() - 1; i++)
            {
                if (strs.get(i).contains ("Go"))
                {
                    method_str = strs.get(i);
                    method_str = method_str.replaceAll("^.*Go ", "");
                }
            }
            if (method_str.equalsIgnoreCase(""))
            {
                method_str = " ";
            }
        }
        canvas.drawText(method_str + " " + bell_position_ringing_now, info_x, info_y - 50, mLabelTextPaint);

        bell_position_ringing_now ++;
        if (bell_position_ringing_now > number_bells)
        {
            if (past % 2 == 1)
            {
                in_handbell_gap = true;
                on_hand_stroke  = true;
            }
            else
            {
                on_hand_stroke  = false;
            }
            bell_position_ringing_now = 1;
            past ++;
        }
    }

    int old_wheres_the_bell = -1;
    private int get_bell_row_position (int current_position)
    {
        // Have to work out the bell that's in the current_position
        boolean first = true;
        int starting_change = past;
        int seen_changes = 0;
        if (strs == null)
        {
            return -1;
        }
        for (int i = starting_change; i <= starting_change; i++)
        {
            String s = "";
            if (i < strs.size ())
            {
                s = strs.get (i);
            }
            else
            {
                return -1;
            }

            if (s.matches(".*ca:bob.*"))
            {
                CURRENT_CALL = "Bob!";
            }
            else if (s.matches(".*ca:single.*"))
            {
                CURRENT_CALL = "Single!";
            }

            if (i == starting_change && !s.startsWith("c:"))
            {
                starting_change ++;
                break;
            }
            if (s.startsWith("c:"))
            {
                // c: 1 2 3 4 5 6
                CURRENTLY_RINGING_STR = s;
                int wheres_the_bell = (s.charAt(1 + 2 * current_position) - '0');
                old_wheres_the_bell = wheres_the_bell;
                seen_changes ++;
                return wheres_the_bell;
            }
            return old_wheres_the_bell;
        }
        return -1;
    }

    private boolean hitTest(float x, float y, PointF dest)
    {
        //System.out.println ("private boolean hitTest(float " + x+". float " + y+". PointF " + dest+".) ");
        if (!mContentRect.contains((int) x, (int) y))
        {
            return false;
        }
        dest.set(
        mCurrentViewport.left
        + mCurrentViewport.width()
        * (x - mContentRect.left) / mContentRect.width(),
        mCurrentViewport.top
        + mCurrentViewport.height()
        * (y - mContentRect.bottom) / -mContentRect.height());
        return true;
    }

    @Override
    public boolean onTouchEvent (MotionEvent event)
    {
        float ex = event.getX ();
        float ey = event.getY ();

        if (allow_swiping)
        {
            boolean retVal = false; // mScaleGestureDetector.onTouchEvent(event);
            //retVal = mGestureDetector.onTouchEvent(event) || retVal;
            if (event.getAction() == MotionEvent.ACTION_DOWN)
            {
                set_clicked_bell(event.getX(), event.getY());
                if (CURRENT_BELL_HIT != -1)
                {
                    retVal = true;
                }
            }
            return retVal; // || super.onTouchEvent(event);
        }
        return super.onTouchEvent (event);
    }
    private final ScaleGestureDetector.OnScaleGestureListener mScaleGestureListener = new ScaleGestureDetector.SimpleOnScaleGestureListener()
    {
        private PointF viewportFocus = new PointF();
        private float lastSpanX;
        private float lastSpanY;
        @Override
        public boolean onScaleBegin(ScaleGestureDetector scaleGestureDetector)
        {
            lastSpanX = scaleGestureDetector.getCurrentSpanX();
            lastSpanY = scaleGestureDetector.getCurrentSpanY();
            return true;
        }
        @Override
        public boolean onScale(ScaleGestureDetector scaleGestureDetector)
        {
            float spanX = scaleGestureDetector.getCurrentSpanX();
            float spanY = scaleGestureDetector.getCurrentSpanY();
            float newWidth = lastSpanX / spanX * mCurrentViewport.width();
            float newHeight = lastSpanY / spanY * mCurrentViewport.height();
            float focusX = scaleGestureDetector.getFocusX();
            float focusY = scaleGestureDetector.getFocusY();
            hitTest(focusX, focusY, viewportFocus);
            mCurrentViewport.set( viewportFocus.x - newWidth * (focusX - mContentRect.left) / mContentRect.width(), viewportFocus.y - newHeight * (mContentRect.bottom - focusY) / mContentRect.height(), 0, 0);
            mCurrentViewport.right = mCurrentViewport.left + newWidth;
            mCurrentViewport.bottom = mCurrentViewport.top + newHeight;
            ViewCompat.postInvalidateOnAnimation(HandBells.this);
            lastSpanX = spanX;
            lastSpanY = spanY;
            return true;
        }
    };

    private final GestureDetector.SimpleOnGestureListener mGestureListener
    = new GestureDetector.SimpleOnGestureListener()
    {
        @Override
        public boolean onDown(MotionEvent e)
        {
            releaseEdgeEffects();
            mScrollerStartViewport.set(mCurrentViewport);
            mScroller.forceFinished(true);
            ViewCompat.postInvalidateOnAnimation(HandBells.this);
            return true;
        }
        @Override
        public boolean onDoubleTap(MotionEvent e)
        {
           // delay -= 10;
            if (delay < 15)
            {
                delay = 15;
            }
            return true;
        }
        @Override
        public boolean onScroll(MotionEvent e1, MotionEvent e2, float distanceX, float distanceY)
        {
            return true;
        }
        @Override
        public boolean onFling(MotionEvent e1, MotionEvent e2, float velocityX, float velocityY)
        {
            fling((int) -velocityX, (int) -velocityY);
            return true;
        }
        @Override
        public void onLongPress(MotionEvent e)
        {
           // delay += 15;
        }
    };
    private void releaseEdgeEffects()
    {
        //System.out.println ("private void releaseEdgeEffects() ");
        mEdgeEffectLeftActive
        = mEdgeEffectTopActive
        = mEdgeEffectRightActive
        = mEdgeEffectBottomActive
        = false;
        mEdgeEffectLeft.onRelease();
        mEdgeEffectTop.onRelease();
        mEdgeEffectRight.onRelease();
        mEdgeEffectBottom.onRelease();
    }
    private void fling(int velocityX, int velocityY)
    {
        //System.out.println ("private void fling(int " + velocityX+". int " + velocityY+".) ");
        releaseEdgeEffects();
        // Flings use math in pixels (as opposed to math based on the viewport).
        computeScrollSurfaceSize(mSurfaceSizeBuffer);
        mScrollerStartViewport.set(mCurrentViewport);
        int startX = (int) (mSurfaceSizeBuffer.x * (mScrollerStartViewport.left - AXIS_X_MIN) / (AXIS_X_MAX - AXIS_X_MIN));
        int startY = (int) (mSurfaceSizeBuffer.y * (AXIS_Y_MAX - mScrollerStartViewport.bottom) / (AXIS_Y_MAX - AXIS_Y_MIN));
        mScroller.forceFinished(true);
        mScroller.fling(
        startX,
        startY,
        velocityX,
        velocityY,
        0, mSurfaceSizeBuffer.x - mContentRect.width(),
        0, mSurfaceSizeBuffer.y - mContentRect.height(),
        mContentRect.width() / 2,
        mContentRect.height() / 2);
        ViewCompat.postInvalidateOnAnimation(this);
    }
    private void computeScrollSurfaceSize(Point out)
    {
        //System.out.println ("private void computeScrollSurfaceSize(Point " + out+".) ");
        out.set( (int) (mContentRect.width() * (AXIS_X_MAX - AXIS_X_MIN) / mCurrentViewport.width()), (int) (mContentRect.height() * (AXIS_Y_MAX - AXIS_Y_MIN) / mCurrentViewport.height()));
    }
    @Override
    public void computeScroll()
    {
        super.computeScroll();
        boolean needsInvalidate = false;
        if (mScroller.computeScrollOffset())
        {
            // The scroller isn't finished, meaning a fling or programmatic pan operation is
            // currently active.
            computeScrollSurfaceSize(mSurfaceSizeBuffer);
            int currX = mScroller.getCurrX();
            int currY = mScroller.getCurrY();
            boolean canScrollX = (mCurrentViewport.left > AXIS_X_MIN || mCurrentViewport.right < AXIS_X_MAX);
            boolean canScrollY = (mCurrentViewport.top > AXIS_Y_MIN || mCurrentViewport.bottom < AXIS_Y_MAX);
            if (canScrollX && currX < 0 && mEdgeEffectLeft.isFinished() && !mEdgeEffectLeftActive)
            {
                mEdgeEffectLeft.onAbsorb((int) OverScrollerCompat.getCurrVelocity(mScroller));
                mEdgeEffectLeftActive = true;
                needsInvalidate = true;
            }
            else if (canScrollX && currX > (mSurfaceSizeBuffer.x - mContentRect.width()) && mEdgeEffectRight.isFinished() && !mEdgeEffectRightActive)
            {
                mEdgeEffectRight.onAbsorb((int) OverScrollerCompat.getCurrVelocity(mScroller));
                mEdgeEffectRightActive = true;
                needsInvalidate = true;
            }
            if (canScrollY && currY < 0 && mEdgeEffectTop.isFinished() && !mEdgeEffectTopActive)
            {
                mEdgeEffectTop.onAbsorb((int) OverScrollerCompat.getCurrVelocity(mScroller));
                mEdgeEffectTopActive = true;
                needsInvalidate = true;
            }
            else if (canScrollY && currY > (mSurfaceSizeBuffer.y - mContentRect.height()) && mEdgeEffectBottom.isFinished() && !mEdgeEffectBottomActive)
            {
                mEdgeEffectBottom.onAbsorb((int) OverScrollerCompat.getCurrVelocity(mScroller));
                mEdgeEffectBottomActive = true;
                needsInvalidate = true;
            }
            float currXRange = AXIS_X_MIN + (AXIS_X_MAX - AXIS_X_MIN) * currX / mSurfaceSizeBuffer.x;
            float currYRange = AXIS_Y_MAX - (AXIS_Y_MAX - AXIS_Y_MIN) * currY / mSurfaceSizeBuffer.y;
            setViewportBottomLeft(currXRange, currYRange);
        }
        if (mZoomer.computeZoom())
        {
            // Performs the zoom since a zoom is in progress (either programmatically or via
            // double-touch).
            float newWidth = (1f - mZoomer.getCurrZoom()) * mScrollerStartViewport.width();
            float newHeight = (1f - mZoomer.getCurrZoom()) * mScrollerStartViewport.height();
            float pointWithinViewportX = (mZoomFocalPoint.x - mScrollerStartViewport.left)
            / mScrollerStartViewport.width();
            float pointWithinViewportY = (mZoomFocalPoint.y - mScrollerStartViewport.top)
            / mScrollerStartViewport.height();
            mCurrentViewport.set(
            mZoomFocalPoint.x - newWidth * pointWithinViewportX,
            mZoomFocalPoint.y - newHeight * pointWithinViewportY,
            mZoomFocalPoint.x + newWidth * (1 - pointWithinViewportX),
            mZoomFocalPoint.y + newHeight * (1 - pointWithinViewportY));
            needsInvalidate = true;
        }
        //if (needsInvalidate)
        {
        //    ViewCompat.postInvalidateOnAnimation(this);
        }
    }
    private void setViewportBottomLeft(float x, float y)
    {
        float curWidth = mCurrentViewport.width();
        float curHeight = mCurrentViewport.height();
        x = Math.max(AXIS_X_MIN, Math.min(x, AXIS_X_MAX - curWidth));
        y = Math.max(AXIS_Y_MIN + curHeight, Math.min(y, AXIS_Y_MAX));
        mCurrentViewport.set(x, y - curHeight, x + curWidth, y);
        ViewCompat.postInvalidateOnAnimation(this);
    }
    public RectF getCurrentViewport()
    {
        return new RectF(mCurrentViewport);
    }
    public void setCurrentViewport(RectF viewport)
    {
        ViewCompat.postInvalidateOnAnimation(this);
    }
    public float getLabelTextSize()
    {
        //System.out.println ("public float getLabelTextSize() ");
        return mLabelTextSize;
    }
    public void setLabelTextSize(float labelTextSize)
    {
        //System.out.println ("public void setLabelTextSize(float " + labelTextSize+". ) ");
        mLabelTextSize = labelTextSize;
        initPaints();
        ViewCompat.postInvalidateOnAnimation(this);
    }
    public int getLabelTextColor()
    {
        //System.out.println ("public int getLabelTextColor() ");
        return mLabelTextColor;
    }
    public void setLabelTextColor(int labelTextColor)
    {
        //System.out.println ("public void setLabelTextColor(int " + labelTextColor+".) ");
        mLabelTextColor = labelTextColor;
        initPaints();
        ViewCompat.postInvalidateOnAnimation(this);
    }
    public float getGridThickness()
    {
        //System.out.println ("public float getGridThickness() ");
        return mGridThickness;
    }
    public void setGridThickness(float gridThickness)
    {
        //System.out.println ("public void setGridThickness(float " + gridThickness+".) ");
        mGridThickness = gridThickness;
        initPaints();
        ViewCompat.postInvalidateOnAnimation(this);
    }
    public int getGridColor()
    {
        //System.out.println ("public int getGridColor() ");
        return mGridColor;
    }
    public void setGridColor(int gridColor)
    {
        //System.out.println ("public void setGridColor(int " + gridColor+".) ");
        mGridColor = gridColor;
        initPaints();
        ViewCompat.postInvalidateOnAnimation(this);
    }
    public float getAxisThickness()
    {
        //System.out.println ("public float getAxisThickness() ");
        return mAxisThickness;
    }
    public void setAxisThickness(float axisThickness)
    {
        //System.out.println ("public void setAxisThickness(float " + axisThickness+".) ");
        mAxisThickness = axisThickness;
        initPaints();
        ViewCompat.postInvalidateOnAnimation(this);
    }
    public int getAxisColor()
    {
        //System.out.println ("public int getAxisColor() ");
        return mAxisColor;
    }
    public void setAxisColor(int axisColor)
    {
        //System.out.println ("public void setAxisColor(int " + axisColor+".) ");
        mAxisColor = axisColor;
        initPaints();
        ViewCompat.postInvalidateOnAnimation(this);
    }
    public float getDataThickness()
    {
        //System.out.println ("public float getDataThickness() ");
        return mDataThickness;
    }
    public void setDataThickness(float dataThickness)
    {
        //System.out.println ("public void setDataThickness(float " + dataThickness+".) ");
        mDataThickness = dataThickness;
    }
    public int getDataColor()
    {
        //System.out.println ("public int getDataColor() ");
        return mDataColor;
    }
    public void setDataColor(int dataColor)
    {
        //System.out.println ("public void setDataColor(int " + dataColor+".) ");
        mDataColor = dataColor;
    }
    @Override
    public Parcelable onSaveInstanceState()
    {
        //System.out.println ("public Parcelable onSaveInstanceState() ");
        Parcelable superState = super.onSaveInstanceState();
        SavedState ss = new SavedState(superState);
        ss.viewport = mCurrentViewport;
        return ss;
    }
    @Override
    public void onRestoreInstanceState(Parcelable state)
    {
        //System.out.println ("public void onRestoreInstanceState(Parcelable " + state+".) ");
        if (!(state instanceof SavedState))
        {
            super.onRestoreInstanceState(state);
            return;
        }
        SavedState ss = (SavedState) state;
        super.onRestoreInstanceState(ss.getSuperState());
        mCurrentViewport = ss.viewport;
    }
    public static class SavedState extends BaseSavedState
    {
        private RectF viewport;
        public SavedState(Parcelable superState)
        {
            super(superState);
        }
        @Override
        public void writeToParcel(Parcel out, int flags)
        {
            super.writeToParcel(out, flags);
            out.writeFloat(viewport.left);
            out.writeFloat(viewport.top);
            out.writeFloat(viewport.right);
            out.writeFloat(viewport.bottom);
        }
        @Override
        public String toString()
        {
            return "BlueLine.SavedState{"
            + Integer.toHexString(System.identityHashCode(this))
            + " viewport=" + viewport.toString() + "}";
        }
        public static final Creator<SavedState> CREATOR
        = ParcelableCompat.newCreator(new ParcelableCompatCreatorCallbacks<SavedState>()
                {
            @Override
            public SavedState createFromParcel(Parcel in, ClassLoader loader)
        {
                return new SavedState(in);
            }
            @Override
            public SavedState[] newArray(int size)
        {
                return new SavedState[size];
            }
        });
        SavedState(Parcel in)
        {
            super(in);
            viewport = new RectF(in.readFloat(), in.readFloat(), in.readFloat(), in.readFloat());
        }
    }
    List <String> strs = null;
    private Timer myTimer;
    public static Boolean currently_ringing = false;


    private boolean DONE_TIMER_ALREADY = false;
    public void draw_blue_line(List<String> astrs)
    {
        setup_initial_params = true;
        strs = astrs;
        if (currently_ringing == true) {
            return;
        }
        currently_ringing = true;
        for (int i = 0; i < astrs.size() - 1; i++)
        {
            String s = astrs.get (i);
            String n = astrs.get (i+1);
            if (!n.startsWith("c:"))
            {
                s = s + ";" + n;
                astrs.set(i, s);
                astrs.remove(i+1);
                i--;
            }
        }
        ViewCompat.postInvalidateOnAnimation(HandBells.this);

        if (DONE_TIMER_ALREADY == false) {
            DONE_TIMER_ALREADY = true;
            myTimer = new Timer();
            myTimer.schedule(new TimerTask() {
                @Override
                public void run() {
                    TimerMethod();
                }
            }, 0, 25);
        }

    }

    int old_timer_counter = 0;
    int TOTAL_TIMER_COUNTER = 0;
    private void force_redraw()
    {
        old_timer_counter = delay - timer_counter;
        //System.out.println("Inside force_redraw at:" + timer_counter + ", change:" + past + " >> " + TOTAL_TIMER_COUNTER);
        timer_counter = delay + 10;
        TimerMethod();
        timer_counter = -old_timer_counter;
        if (timer_counter < -1 * delay)
        {
            timer_counter = 0;
        }
    }

    private void TimerMethod()
    {
        timer_counter++;
        TOTAL_TIMER_COUNTER ++;
        //System.out.println("Inside timer:" + timer_counter + " vs " + delay + " >> " + TOTAL_TIMER_COUNTER);

        if (in_handbell_gap && timer_counter >= delay)
        {
            timer_counter = delay - 15;
            in_handbell_gap = false;
        }

        if (timer_counter >= delay)
        {
            timer_counter = 0;
            ViewCompat.postInvalidateOnAnimation(HandBells.this);
        }
    }
    // From entelecom code:
    // Process all files and directories under dir
    static List <String> paths_to_bells = new ArrayList <String> ();
    static HashMap <String, Integer> bell_files = new HashMap<String, Integer> ();
    public static void visitAllDirsAndFiles (File dir, int level)
    {
        if (level > 4) { return; }
        if (dir.getName ().toLowerCase().matches(".+\\.bell$"))
        {
            // Found one
            if (!bell_files.containsKey (dir.getName ()))
            {
                bell_files.put (dir.getName(), new Integer(1));
                paths_to_bells.add (dir.getAbsolutePath ());
            }
        }
        if (dir.isDirectory())
        {
            String[] children = dir.list();
            if (children != null) {
                for (int i = 0; i < children.length; i++) {
                    visitAllDirsAndFiles(new File(dir, children[i]), level + 1);
                }
            }
        }
    }

    public static void writeBellFile(File dir, String sFileName, String sBody)
    {
        if(!dir.exists()){
            dir.mkdir();
        }

        try {
            File gpxfile = new File(dir, sFileName);
            FileWriter writer = new FileWriter(gpxfile);
            writer.append(sBody);
            writer.flush();
            writer.close();

        } catch (Exception e) {
            e.printStackTrace ();
        }
    }

    public static File getDefaultBellFile(File dir)
    {
        writeBellFile (dir, "Plain_Bob_Minor_handbells.bell", "6\nPlain Bob Minor 240\nRepeat\nX.1,6.X.1,6.X.1,6.X.1,6.X.1,6.X.\nUntil Rounds\nPlainHunt\nPlainLead\n1,2.\nBobLead\n1,4.\nSingleLead\n1,2,3,4.\nMethod\n-,P,P,P,P,S,P,P,P,P,-,P,P,P,P,S,P,P,P,P.\n");

        try {
            File gpxfile = new File(dir, "Plain_Bob_Minor_handbells.bell");

            if(gpxfile.exists()){
                return gpxfile;
            }
        } catch (Exception e) {
            e.printStackTrace ();
        }
        return null;
    }

    public void writeBellFiles(Context mcoContext)
    {
        File dir = mcoContext.getFilesDir();
        writeBellFile (dir, "PlainHunt_4.bell", "4\nPlainHunt 4\nRepeat\nx.1,4.x.\nUntil Rounds\nTrebleBob\nPlainLead\n1,4.\nBobLead\n1,4.\nSingleLead\n1,4.\nMethod\nP,P,P,P,P,P.\n");
        writeBellFile (dir, "Plain_Bob_Minor_handbells.bell", "6\nPlain Bob Minor 240\nRepeat\nX.1,6.X.1,6.X.1,6.X.1,6.X.1,6.X.\nUntil Rounds\nPlainHunt\nPlainLead\n1,2.\nBobLead\n1,4.\nSingleLead\n1,2,3,4.\nMethod\n-,P,P,P,P,S,P,P,P,P,-,P,P,P,P,S,P,P,P,P.\n");
        writeBellFile (dir, "Reverse_Bob_Minimus.bell", "4\nReverse Bob Minimus\nRepeat\nx.1,4.x.3,4.x.1,4.x.\nUntil Rounds\nPlainHunt\nPlainLead\n1,4.\nBobLead\n1,2.\nSingleLead\n\nMethod\nP.");
        writeBellFile (dir, "Grandsire_Doubles.bell", "5\nGrandsire Doubles\nRepeat\n3.1.5.1.5.1.5.\nUntil Rounds\nPrinciple\nPlainLead\n1.5.1.\nBobLead\n1.3.1.\nSingleLead\n1.3.1,2,3.\nMethod\n-,S,P,S,-,S,P,S,-,S,P,S.\n");
        writeBellFile (dir, "Plain_Bob_Doubles.bell", "5\nPlain Bob Doubles\nRepeat\n5.1.\nUntil Rounds\nPlainHunt\nPlainLead\n1,2,5.\nBobLead\n1,4,5.\nSingleLead\n\nMethod\nP.8\nPlain Bob Major\nRepeat\nX.1,8.X.1,8.X.1,8.X.1,8.X.1,8.X.1,8.X.\nUntil Rounds\nPlainHunt\nPlainLead\n1,2.\nBobLead\n1,4.\nSingleLead\n1,2,3,4.\nMethod\nP.\n");
        writeBellFile (dir, "PlainHunt_5.bell", "5\nPlainHunt 5\nRepeat\n5.1.5.1.5.1.5.1.5.1.5.1.5.1.\nUntil Rounds\nTrebleBob\nPlainLead\n1.\nBobLead\n1.\nSingleLead\n1.\nMethod\nP,P,P,P,P,P.\n");
        writeBellFile (dir, "StedmanDoubles.bell", "5\nStedmanDoubles\nRepeat\n3.1.5.\nUntil Rounds\nPrinciple\nPlainLead\n3.1.3.1.3.5.1.3.1.\nBobLead\n\nSingleLead\n3.1.3,4,5.1.3.5.1.3.1.\nMethod\nP.");
        writeBellFile (dir, "StedmanDoubles.bell", "5\nStedmanDoubles\nRepeat\n3.1.5.\nUntil Rounds\nPrinciple\nPlainLead\n3.1.3.1.3.5.1.3.1.\nBobLead\n\nSingleLead\n3.1.3,4,5.1.3.5.1.3.1.\nMethod\nP.  ");
        writeBellFile (dir, "Cambridge_Surprise_Minor.bell", "6\nCambridge Surprise Minor\nRepeat\nx.3,6.x.1,4.x.1,2.x.3,6.x.1,4.x.5,6.x.1,4.x.3,6.x.1,2.x.1,4.x.3,6.x.\nUntil Rounds\nTrebleBob\nPlainLead\n1,2.\nBobLead\n1,4.\nSingleLead\n1,2,3,4.\nMethod\nP.\n");
        writeBellFile (dir, "London_Surprise_Minor.bell", "6\nLondon Surprise Minor\nRepeat\n3,6.x.3,6.1,4.x.1,2.x.3,6.1,4.x.3,6.1,4.3,6.x.1,4.3,6.x.1,2.x.1,4.3,6.x.3,6.\nUntil Rounds\nTrebleBob\nPlainLead\n1,2. \nBobLead\n1,4.\nSingleLead\n1,2,3,4.\nMethod\nP.\n");
        writeBellFile (dir, "Plain_Bob_Minor.bell", "6\nPlain Bob Minor\nRepeat\nX.1,6.X.1,6.X.1,6.X.1,6.X.1,6.X.\nUntil Rounds\nPlainHunt\nPlainLead\n1,2.\nBobLead\n1,4.\nSingleLead\n1,2,3,4.\nMethod\nP.\n10\nPlainHunt 10\nRepeat\nx.1,10.x.\nUntil Rounds\nTrebleBob\nPlainLead\n1,10.\nBobLead\n1,10.\nSingleLead\n1,10.\nMethod\nP,P,P,P,P,P.\n");
        writeBellFile (dir, "PlainHunt_6.bell", "6\nPlainHunt 6\nRepeat\nx.1,6.x.\nUntil Rounds\nTrebleBob\nPlainLead\n1,6.\nBobLead\n1,6.\nSingleLead\n1,6.\nMethod\nP,P,P,P,P,P.\n");
        writeBellFile (dir, "PlainHunt_7.bell", "7\nPlainHunt 7\nRepeat\n7.1.7.1.7.1.7.1.7.1.7.1.7.1.7.1.7.1.\nUntil Rounds\nTrebleBob\nPlainLead\n7.\nBobLead\n7.\nSingleLead\n7.\nMethod\nP,P,P,P,P,P.\n");
        writeBellFile (dir, "Bristol_Surprise_Major.bell", "8\nBristol Surprise Major\nRepeat\nx.5,8.x.1,4.5,8.x.5,8.3,6.1,4.x.1,4.5,8.x.1,4.x.1,8.x.1,4.x.5,8.1,4.x.1,4.3,6.5,8.x.5,8.1,4.x.5,8.x.\nUntil Rounds\nTrebleBob\nPlainLead\n1,8.\nBobLead\n1,4.\nSingleLead\n1,2,3,4.\nMethod\nP,S,-,-,P,P,P,P,P,P,-,P,S,P,-,P,P,-,P,P.\n");
        writeBellFile (dir, "Cambridge_Surprise_Major.bell", "8\nCambridge Surprise Major\nRepeat\nx.3,8.x.1,4.x.1,2,5,8.x.3,6.x.1,4.x.5,8.x.1,6.x.7,8.x.1,6.x.5,8.x.1,4.x.3,6.x.1,2,5,8.x.1,4.x.3,8.x.\nUntil Rounds\nTrebleBob\nPlainLead\n1,2.\nBobLead\n1,4.\nSingleLead\n1,2,3,4.\nMethod\nP,S,P,S,S,P,P,P,-,P,P,P,-,-,-,-,-,S,S,S,P.\n");
        writeBellFile (dir, "Manuka_Surprise_Major.bell", "8\nManuka Surprise Major\nRepeat\nx.5,8.x.1,6.x.1,2,5,8.x.1,6.x.1,4.x.1,2,3,8.x.1,4.x.7,8.x.1,4.x.1,2,3,8.x.1,4.x.1,6.x.1,2,5,8.x.1,6.x.5,8.x.\nUntil Rounds\nTrebleBob\nPlainLead\n1,2.\nBobLead\n1,4.\nSingleLead\n1,2,3,4.\nMethod\nS,-,P,S,S,P,P,P,P,P,P,-,-,S,-,P,S,-,S.\n");
        writeBellFile (dir, "PlainHunt_8.bell", "8\nPlainHunt 8\nRepeat\nx.1,8.x.\nUntil Rounds\nTrebleBob\nPlainLead\n1,8.\nBobLead\n1,8.\nSingleLead\n1,8.\nMethod\nP,P,P,P,P,P.\n");
        writeBellFile (dir, "Yorkshire_Surprise_Major.bell", "8\nYorkshire Surprise Major\nRepeat\nx.3,8.x.1,4.x.5,8.x.1,6.x.1,2.x.3,8.x.1,4.x.7,8.x.1,4.x.3,8.x.1,2.x.1,6.x.5,8.x.1,4.x.3,8.x.\nUntil Rounds\nTrebleBob\nPlainLead\n1,2.\nBobLead\n1,4.\nSingleLead\n1,2,3,4.\nMethod\nS,P,S,-,-,P,P,P,P,P,P,-,S,P,P,S,S,P,S.\n");
        writeBellFile (dir, "Yorkshire_Surprise_Major.bell", "8\nYorkshire Surprise Major\nRepeat\nx.3,8.x.1,4.x.5,8.x.1,6.x.1,2.x.3,8.x.1,4.x.7,8.x.1,4.x.3,8.x.1,2.x.1,6.x.5,8.x.1,4.x.3,8.x.\nUntil Rounds\nTrebleBob\nPlainLead\n1,2.\nBobLead\n1,4.\nSingleLead\n1,2,3,4.\nMethod\nS,P,S,-,-,P,P,P,P,P,P,-,S,P,P,S,S,P,S.\n");
        writeBellFile (dir, "PlainHunt_9.bell", "9\nPlainHunt 9\nRepeat\n9.1.9.1.9.1.9.1.9.1.9.1.9.1.9.1.9.1.9.1.\nUntil Rounds\nTrebleBob\nPlainLead\n9.\nBobLead\n9.\nSingleLead\n9.\nMethod\nP,P,P,P,P,P.\n");
    }

    public void find_bell_dirs()
    {
        try
        {
            // This filter only returns .bell files!
            bell_files = new HashMap <String, Integer> ();
            //visitAllDirsAndFiles (new File (Environment.getExternalStorageDirectory(), "."), 2);
            visitAllDirsAndFiles (new File (getContext().getFilesDir(), "."), 2);
        }
        catch (Exception e)
        {
            e.printStackTrace();
            //System.out.println("eee:" + e);
        }
    }

    // http://stackoverflow.com/questions/3592717/choose-file-dialog
    //In an Activity
    private String [] files;
    private File mPath = new File (Environment.getExternalStorageDirectory() + "//");
    private static final String FTYPE = ".bell";
    public static final int DIALOG_LOAD_FILE = 1000;
    static public Dialog onCreateDialog2(int id, final File dir)
    {
        Dialog dialog = null;
        AlertDialog.Builder builder = new AlertDialog.Builder(MultiBell.t);
        switch(id)
        {
            case DIALOG_LOAD_FILE:
                builder.setTitle ("Choose the method you wish to ring");
                if (paths_to_bells == null)
                {
                    System.out.print ("Showing file picker before loading the file list");
                    dialog = builder.create();
                    return dialog;
                }
                builder. setItems( paths_to_bells.toArray(new CharSequence[paths_to_bells.size()]), new DialogInterface.OnClickListener()
                {
                    public void onClick(DialogInterface dialog, int which)
                    {
                        MultiBell.mChosenFile = paths_to_bells.get(which);
                        MultiBell.last_method = "";
                        MultiBell.last_bell = -1;
                        MultiBell.second_last_bell = -1;
                        if (MultiBell.mChosenFile != null && !MultiBell.mChosenFile.equals(""))
                        {
                            MultiBell.last_method = MultiBell.mChosenFile ;
                            MultiBell.last_bell = HandBells.chosen_bell;
                            MultiBell.second_last_bell = HandBells.second_chosen_bell;
                            MultiBell.ring_the_method (MultiBell.mChosenFile, false, dir.getAbsoluteFile());
                        }
                    }
                });
                break;
        }
        builder.setCancelable(false);
        dialog = builder.show();
        return dialog;
    }
}
