package com.otique.handbell2020;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.DialogInterface;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.os.Handler;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.MotionEvent;
import android.view.View;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.Toast;

import androidx.appcompat.app.ActionBar;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import java.io.File;
import java.util.List;

import static com.otique.handbell2020.HandBells.DIALOG_LOAD_FILE;
import static com.otique.handbell2020.HandBells.onCreateDialog2;

/**
 * An example full-screen activity that shows and hides the system UI (i.e.
 * status bar and navigation/system bar) with user interaction.
 */
public class MultiBell extends AppCompatActivity {
    private static final boolean AUTO_HIDE = true;
    private static final int MY_PERMISSIONS_REQUEST_READ_STORAGE = 78;
    private static final int MY_PERMISSIONS_REQUEST_WRITE_STORAGE = 79;
    static MultiBell t = null;
    private static HandBells mGraphView = null;
    private static final int AUTO_HIDE_DELAY_MILLIS = 3000;
    private static final int UI_ANIMATION_DELAY = 300;
    private final Handler mHideHandler = new Handler();
    private View mContentView;
    private final Runnable mHidePart2Runnable = new Runnable() {
        @SuppressLint("InlinedApi")
        @Override
        public void run() {
            // Delayed removal of status and navigation bar

            // Note that some of these constants are new as of API 16 (Jelly Bean)
            // and API 19 (KitKat). It is safe to use them, as they are inlined
            // at compile-time and do nothing on earlier devices.
            mContentView.setSystemUiVisibility(View.SYSTEM_UI_FLAG_LOW_PROFILE
                    | View.SYSTEM_UI_FLAG_FULLSCREEN
                    | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION);
        }
    };
    private View mControlsView;
    private final Runnable mShowPart2Runnable = new Runnable() {
        @Override
        public void run() {
            // Delayed display of UI elements
            ActionBar actionBar = getSupportActionBar();
            if (actionBar != null) {
                actionBar.show();
            }
            mControlsView.setVisibility(View.VISIBLE);
        }
    };


    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        super.onCreateOptionsMenu(menu);
        getMenuInflater().inflate(R.menu.main, menu);
        return true;
    }

    private boolean mVisible;
    private final Runnable mHideRunnable = new Runnable() {
        @Override
        public void run() {
            hide();
        }
    };
    /**
     * Touch listener to use for in-layout UI controls to delay hiding the
     * system UI. This is to prevent the jarring behavior of controls going away
     * while interacting with activity UI.
     */
    private final View.OnTouchListener mDelayHideTouchListener = new View.OnTouchListener() {
        @Override
        public boolean onTouch(View view, MotionEvent motionEvent) {
            if (AUTO_HIDE) {
                delayedHide(AUTO_HIDE_DELAY_MILLIS);
            }
            return false;
        }
    };
    public static String mChosenFile;
    public static String last_method = "";
    public static int last_bell = -1;
    public static int second_last_bell = -1;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_single_bell);
        mGraphView = (HandBells) findViewById(R.id.chart);

        mVisible = true;
        mControlsView = findViewById(R.id.fullscreen_content_controls);
        mContentView = findViewById(R.id.fullscreen_content);

        t = this;
        // Set up the user interaction to manually show or hide the system UI.
        mContentView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                toggle();
            }
        });

        // Upon interacting with UI controls, delay any scheduled hide()
        // operations to prevent the jarring behavior of controls going away
        // while interacting with the UI.
        findViewById(R.id.blueline_run).setOnTouchListener(mDelayHideTouchListener);
    }


    static boolean ring_bob = false;
    static boolean ring_single = false;
    static boolean ring_plain = false;
    static boolean ring_fm_file = false;
    static boolean last_ring_plain = false;
    static boolean last_ring_single = false;
    static boolean last_ring_bob = false;
    static boolean last_ring_fm_file = false;

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {

        switch (item.getItemId()) {
            case R.id.action_user_options:
                get_user_input ();
                return true;

            case R.id.action_replay:
                ring_the_method (last_method, true, getApplicationContext().getFilesDir());
                return true;

            case R.id.action_1and2:
                HandBells.chosen_bell = 1;
                HandBells.second_chosen_bell = 2;
                ring_the_method (last_method, true, getApplicationContext().getFilesDir());
                return true;

            case R.id.action_3and4:
                HandBells.chosen_bell = 3;
                HandBells.second_chosen_bell = 4;
                ring_the_method (last_method, true, getApplicationContext().getFilesDir());
                return true;

            case R.id.action_5and6:
                HandBells.chosen_bell = 5;
                HandBells.second_chosen_bell = 6;
                ring_the_method (last_method, true, getApplicationContext().getFilesDir());
                return true;

            case R.id.action_ring_single:
            case R.id.action_ring_bob:
            case R.id.action_ring:
            case R.id.action_ring_from_file:
                Ring r = new Ring ();
                ring_plain = false;
                ring_single = false;
                ring_bob = false;
                ring_fm_file = false;
                mGraphView.writeBellFiles(getApplicationContext());

                if (item.getItemId() == R.id.action_ring_bob)
                {
                    ring_bob = true;
                }
                if (item.getItemId() == R.id.action_ring_single)
                {
                    ring_single = true;
                }
                if (item.getItemId() == R.id.action_ring)
                {
                    ring_plain = true;
                }
                if (item.getItemId() == R.id.action_ring_from_file)
                {
                    ring_fm_file = true;
                }

                mChosenFile = "";
                mGraphView.find_bell_dirs ();
                Dialog d = onCreateDialog2(DIALOG_LOAD_FILE, getApplicationContext().getFilesDir());
                d.show();
                String f = mChosenFile;

                try {
                    getApplicationContext().fileList();
                } catch (Exception e) {
                    // e.printStackTrace();
                    //txtHelp.setText("Error: can't show help.");
                }
                if (mChosenFile != null && !mChosenFile.equals(""))
                {
                    List<String> strs = r.touch_from_file(mChosenFile);
                    mGraphView.draw_blue_line (strs);
                }
                return true;
        }
        return super.onOptionsItemSelected(item);
    }

    public static void ring_the_method(String mChosenFile, boolean from_last, File dir)
    {
        File mFileToRing;
        if (mChosenFile == null || mChosenFile.equals(""))
        {
            //mChosenFile = "/storage/emulated/0/./Download/PlainBobMinor.bell";
            mFileToRing = HandBells.getDefaultBellFile(dir);
            mChosenFile = mFileToRing.getAbsolutePath();
            ring_fm_file = true;
            ring_bob = false;
            ring_single = false;
            ring_plain = false;
            ring_fm_file = true;
            last_ring_plain = false;
            last_ring_single = false;
            last_ring_bob = false;
            last_ring_fm_file = true;
            from_last = false;
        }
        if (mChosenFile != null && !mChosenFile.equals(""))
        {
            last_method = mChosenFile;
            last_bell = HandBells.chosen_bell;
            second_last_bell = HandBells.second_chosen_bell;
            Ring r = new Ring ();
            if (ring_single && !from_last || last_ring_single && from_last)
            {
                last_ring_plain = false;
                last_ring_bob = false;
                last_ring_single = true;
                last_ring_fm_file = false;
                List <String> strs = r.single_from_file(mChosenFile);
                mGraphView.draw_blue_line (strs);
            }
            else if (ring_bob && !from_last || last_ring_bob && from_last)
            {
                last_ring_plain = false;
                last_ring_bob = true;
                last_ring_single = false;
                last_ring_fm_file = false;
                List <String> strs = r.bob_from_file(mChosenFile);
                mGraphView.draw_blue_line (strs);
            }
            else if (ring_fm_file && !from_last || last_ring_fm_file && from_last)
            {
                last_ring_plain = false;
                last_ring_bob = false;
                last_ring_single = false;
                last_ring_fm_file = true;
                List <String> strs = r.touch_from_file (mChosenFile);
                mGraphView.draw_blue_line (strs);
            }
            else if (ring_plain && !from_last || last_ring_plain && from_last)
            {
                last_ring_plain = true;
                last_ring_bob = false;
                last_ring_single = false;
                last_ring_fm_file = false;
                List <String> strs = r.plain_touch (mChosenFile);
                mGraphView.draw_blue_line (strs);
            }
        }
    }


    static View textEntryView = null;
    private void get_user_input () {
        // Get data via the dialogs..
        LayoutInflater factory = LayoutInflater.from(this);

        textEntryView = factory.inflate(R.layout.user_input, null);

        AlertDialog alert = new AlertDialog.Builder(this)
                .setTitle(R.string.user_input)
                .setView(textEntryView)

                .setPositiveButton(R.string.ok_button, new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int whichButton) {
                        // Get the User's info hash to the new values...
                        save_users_values(textEntryView);
                    }
                })
                .setNegativeButton(R.string.cancel_button, new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int whichButton) {
                        /* User clicked cancel so do some stuff */
                    }
                })
                .create();


        // Set up values..
        RadioGroup r = (RadioGroup) textEntryView.findViewById(R.id.controls);
        if (r != null) {
            if (HandBells.show_controls && !HandBells.allow_swiping) {
                r.check(R.id.radio1);
            } else if (!HandBells.show_controls && HandBells.allow_swiping) {
                r.check(R.id.radio2);
            } else {
                r.check(R.id.radio3);
            }
        }

        CheckBox c = (CheckBox) textEntryView.findViewById(R.id.rand_bell_checkbox);
        EditText a = (EditText) textEntryView.findViewById(R.id.bell_number_edit);
        if (c != null && a != null) {
            if (HandBells.chosen_bell == -1) {
                c.setChecked(true);
                a.setText("");
            } else {
                c.setChecked(false);
                a.setText("" + HandBells.chosen_bell);
            }
        }
        
        a = (EditText) textEntryView.findViewById(R.id.bell_number_edit2);
        if (c != null && a != null) {
            if (HandBells.second_chosen_bell == -1) {
                a.setText("");
            } else {
                a.setText("" + HandBells.second_chosen_bell);
            }
        }


        a = (EditText) textEntryView.findViewById(R.id.animation_edit);
        if (a != null) {
            a.setText("" + HandBells.delay);
        }

        alert.show();
    }

    private void save_users_values(View textEntryView)
    {
        // Save the user's values for them!
        EditText a = null;
        a = (EditText) textEntryView.findViewById (R.id.bell_number_edit);
        if (a != null)
        {
            try
            {
                a = (EditText) textEntryView.findViewById (R.id.bell_number_edit);
                int x = Integer.parseInt(a.getText ().toString());
                HandBells.chosen_bell = x;
                a = (EditText) textEntryView.findViewById (R.id.bell_number_edit2);
                x = Integer.parseInt(a.getText ().toString());
                HandBells.second_chosen_bell = x;
            }
            catch (Exception e)
            {
                HandBells.chosen_bell = -1;
                HandBells.second_chosen_bell = -1;
            }
        }

        CheckBox c = (CheckBox) textEntryView.findViewById(R.id.rand_bell_checkbox);
        if (c != null && c.isChecked())
        {
            HandBells.chosen_bell = -1;
        }

        RadioGroup r  = (RadioGroup) textEntryView.findViewById(R.id.controls);
        int id = r.getCheckedRadioButtonId();

        if (id != -1)
        {
            RadioButton b = (RadioButton) textEntryView.findViewById(id);
            if (b != null)
            {
                String text = b.getText().toString();

                if (text.equalsIgnoreCase ("Use L/R buttons only")) { HandBells.show_controls = true; HandBells.allow_swiping = false; }
                if (text.equalsIgnoreCase ("Hide L/R buttons "))    { HandBells.show_controls = false; HandBells.allow_swiping = true; }
                if (text.equalsIgnoreCase ("Use Both"))             { HandBells.show_controls = true; HandBells.allow_swiping = true; }
            }
        }

        a = (EditText) textEntryView.findViewById (R.id.animation_edit);
        if (a != null)
        {
            try
            {
                a = (EditText) textEntryView.findViewById (R.id.animation_edit);
                int x = Integer.parseInt(a.getText ().toString());
                HandBells.delay = x;
                HandBells.ORIGINAL_DELAY = x;
            }
            catch (Exception e)
            {
            }
        }
    }


        @Override
    protected void onPostCreate(Bundle savedInstanceState) {
        super.onPostCreate(savedInstanceState);
    }

    private void toggle() {
        if (HandBells.currently_ringing == false) {
            if (mVisible) {
                hide();
            } else {
                show();
            }
        } else {
            hide();
        }
    }

    private void hide() {
        // Hide UI first
        ActionBar actionBar = getSupportActionBar();
        if (actionBar != null) {
            actionBar.hide();
        }
        mControlsView.setVisibility(View.GONE);
        mVisible = false;

        // Schedule a runnable to remove the status and navigation bar after a delay
        mHideHandler.removeCallbacks(mShowPart2Runnable);
        mHideHandler.postDelayed(mHidePart2Runnable, UI_ANIMATION_DELAY);
    }

    @SuppressLint("InlinedApi")
    private void show() {
        // Show the system bar
        mContentView.setSystemUiVisibility(View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION);
        mVisible = true;

        // Schedule a runnable to display UI elements after a delay
        mHideHandler.removeCallbacks(mHidePart2Runnable);
        mHideHandler.postDelayed(mShowPart2Runnable, UI_ANIMATION_DELAY);
    }

    /**
     * Schedules a call to hide() in delay milliseconds, canceling any
     * previously scheduled calls.
     */
    private void delayedHide(int delayMillis) {
        mHideHandler.removeCallbacks(mHideRunnable);
        mHideHandler.postDelayed(mHideRunnable, delayMillis);
    }

    public void checkPermissionReadStorage(Activity activity){
        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.READ_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            if (ActivityCompat.shouldShowRequestPermissionRationale(activity, Manifest.permission.READ_EXTERNAL_STORAGE)) {
            } else {
                ActivityCompat.requestPermissions(activity, new String[]{Manifest.permission.READ_EXTERNAL_STORAGE}, MY_PERMISSIONS_REQUEST_READ_STORAGE);
            }
        }
        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            if (ActivityCompat.shouldShowRequestPermissionRationale(activity, Manifest.permission.WRITE_EXTERNAL_STORAGE)) {
            } else {
                ActivityCompat.requestPermissions(activity, new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE}, MY_PERMISSIONS_REQUEST_WRITE_STORAGE);
            }
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode,
                                           String permissions[], int[] grantResults) {
        switch (requestCode) {
            case MY_PERMISSIONS_REQUEST_READ_STORAGE: {
                // premission to read storage
                if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                } else {
                    Toast.makeText(this, "Needs permission to access external storage to proceed", Toast.LENGTH_SHORT).show();
                }
                return;
            }
            case MY_PERMISSIONS_REQUEST_WRITE_STORAGE: {
                // premission to read storage
                if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                } else {
                    Toast.makeText(this, "Needs permission to write to external storage to proceed", Toast.LENGTH_SHORT).show();
                }
                return;
            }


            // other 'case' lines to check for other
            // permissions this app might request
        }
    }
}
