package com.goomsdk.view;

import android.content.Context;
import android.graphics.Color;
import android.util.AttributeSet;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.view.View;
import android.util.Log;

import androidx.constraintlayout.widget.ConstraintLayout;

import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.Vector;

import us.zoom.sdk.ZoomVideoSDKUser;
import us.zoom.sdk.ZoomVideoSDKVideoCanvas;
import us.zoom.sdk.ZoomVideoSDKVideoView;
import us.zoom.sdk.ZoomVideoSDKVideoAspect;

import com.goomsdk.util.UserHelper;

import org.godotengine.godot.Dictionary;

public class CameraStackLayout extends FrameLayout {

//    private List<ZoomVideoSDKUser> _userList = new Vector<>();
    private HashMap<ZoomVideoSDKUser, ZoomVideoSDKVideoView> userViews = new HashMap<>();
    private HashMap<String, ViewGroup> extraViews = new HashMap<>();
    private HashMap<String, DrawLayout> drawLayouts = new HashMap<>();
//    private DrawLayout dummy_view_layout = new DrawLayout();
    protected static final String SelfParent = "";

    // used for debugging
    private List<BasicVideoContainer> dummy_views = new Vector<BasicVideoContainer>();

    public void reload_layouts() {
        List<ZoomVideoSDKUser> user_list = UserHelper.getAllUsers();
        {
            for (Map.Entry<String, DrawLayout> entry : drawLayouts.entrySet()) {
                // see if user view exists
                if(extraViews.containsKey(entry.getKey())) {
                    entry.getValue().configureTarget(extraViews.get(entry.getKey()));
                }
            }
        }
    }

    public CameraStackLayout(Context context) {
        super(context);
        create_extra_layouts(context);
        reload_layouts();
    }

    public CameraStackLayout(Context context, AttributeSet attrs) {
        super(context, attrs, 0);
        create_extra_layouts(context);
        reload_layouts();
    }

    private void create_extra_layouts(Context context) {
        FrameLayout teacherFrame = new FrameLayout(context);
        FrameLayout studentStack = new FrameLayout(context);
//        LinearLayout studentStack = new LinearLayout(context);
//        studentStack.setOrientation(LinearLayout.HORIZONTAL);
        addView(teacherFrame);
        addView(studentStack);
        teacherFrame.setId(1001);
        studentStack.setId(1002);
        extraViews.put("teacherFrame", teacherFrame);
        extraViews.put("studentStack", studentStack);

//        dummy_view_layout.width = 300;
//        dummy_view_layout.height = 200;
    }

    public void addUser(ZoomVideoSDKUser user) {
        Log.i("godot", "CameraStackLayout.addUser called");
        ZoomVideoSDKVideoView videoView = new ZoomVideoSDKVideoView(getContext());
        ZoomVideoSDKVideoCanvas canvas = user.getVideoCanvas();
        canvas.subscribe(videoView, ZoomVideoSDKVideoAspect.ZoomVideoSDKVideoAspect_Original);

        if (isTeacher(user)) {
            extraViews.get("teacherFrame").addView(videoView);
        } else {
            extraViews.get("studentStack").addView(videoView);
        }
        userViews.put(user, videoView);
        reload_layouts();
    }

    public void removeUser(ZoomVideoSDKUser user) {
        View v = userViews.get(user);
        try {
            extraViews.get("teacherFrame").removeView(v);
        }
        catch (Exception e) {

        }
        try {
            extraViews.get("studentStack").removeView(v);
        }
        catch (Exception e) {

        }
        reload_layouts();
    }

    public void clear() {
    }

    public void configureLayout(Dictionary cdict) {
        drawLayouts.clear();
        for (Map.Entry<String, Object> entry : cdict.entrySet()) {
            String key = entry.getKey();
            Object value = entry.getValue();
            if (!(value instanceof Dictionary)) {
                // ignore invalid option
                Log.d("Godot", String.format("Invalid Layout configuration for key '%s'", key));
                continue;
            }
            Log.i("Godot", String.format("Parsing layout options for key '%s'", key));
            Dictionary v = (Dictionary) value;
            drawLayouts.put(key, new DrawLayout(v));
        }
        reload_layouts();
    }

    public boolean isTeacher(ZoomVideoSDKUser user) {
        if (user.getUserName().equals("teacher")) {
            return true;
        } else {
            return false;
        }
    }

    public void add_dummy_view() {
        Log.d("godot", "add_dummy_view called");
        BasicVideoContainer dv = new BasicVideoContainer(getContext());

        extraViews.get("studentStack").addView(dv);
    }

//    public void get



}
