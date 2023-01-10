package com.goomsdk.view;

import android.view.View;
import android.widget.FrameLayout;
import java.util.Map;
import android.util.Log;

import org.godotengine.godot.Dictionary;

public class DrawLayout {
    int top = 0; int left = 0; int height = 100; int width = 100;
    String id = ""; String parent_id = ""; String type = "single";

    public DrawLayout() {

    }

    public DrawLayout(Dictionary cdict) {
        reinit(cdict);
    }

    public boolean is_compatible_with(Dictionary cdict) {
        if (cdict == null) {
            return false;
        }
        if (cdict.containsKey("parent_id")) {
            Object value = cdict.get("parent_id");
            if(!(value instanceof String)) {
                // ignore invalid option
                Log.d("Godot", String.format("Invalid Option passed to DrawLayout"));
                return false;
            }
            String v = (String) value;
            if (!v.equals(parent_id)) {
                return false;
            }
        }
        else return false;
        if(cdict.containsKey("id")) {
            Object value = cdict.get("id");
            if(!(value instanceof String)) {
                // ignore invalid option
                Log.d("Godot", String.format("Invalid Option passed to DrawLayout"));
                return false;
            }
            String v = (String) value;
            if (!v.equals(id)) {
                return false;
            }
        }
        else return false;
        if(cdict.containsKey("type")) {
            Object value = cdict.get("type");
            if(!(value instanceof String)) {
                // ignore invalid option
                Log.d("Godot", String.format("Invalid Option passed to DrawLayout"));
                return false;
            }
            String v = (String) value;
            if (!v.equals(type)) {
                return false;
            }
        }
        else return false;
        return true;
    }

    public void reinit(Dictionary cdict) {
        for (Map.Entry<String, Object> entry : cdict.entrySet()) {
            String key = entry.getKey();
            Object value = entry.getValue();

            switch (key) {
                case "top": {
                    if (!(value instanceof Integer)) {
                        // ignore invalid option
                        Log.d("Godot", String.format("Invalid Option passed to DrawLayout with key = '%s'", key));
                        continue;
                    }
                    Integer v = (Integer) value;
                    top = v;
                    break;
                }
                case "left": {
                    if (!(value instanceof Integer)) {
                        // ignore invalid option
                        Log.d("Godot", String.format("Invalid Option passed to DrawLayout with key = '%s'", key));
                        continue;
                    }
                    Integer v = (Integer) value;
                    left = v;
                    break;
                }
                case "width": {
                    if (!(value instanceof Integer)) {
                        // ignore invalid option
                        Log.d("Godot", String.format("Invalid Option passed to DrawLayout with key = '%s'", key));
                        continue;
                    }
                    Integer v = (Integer) value;
                    width = v;
                    break;
                }
                case "height": {
                    if (!(value instanceof Integer)) {
                        // ignore invalid option
                        Log.d("Godot", String.format("Invalid Option passed to DrawLayout with key = '%s'", key));
                        continue;
                    }
                    Integer v = (Integer) value;
                    height = v;
                    break;
                }
                case "id": {
                    if (!(value instanceof String)) {
                        // ignore invalid option
                        Log.d("Godot", String.format("Invalid Option passed to DrawLayout with key = '%s'", key));
                        continue;
                    }
                    String v = (String) value;
                    id = v;
                    break;
                }
                case "parent_id": {
                    if (!(value instanceof String)) {
                        // ignore invalid option
                        Log.d("Godot", String.format("Invalid Option passed to DrawLayout with key = '%s'", key));
                        continue;
                    }
                    String v = (String) value;
                    parent_id = v;
                    break;
                }
                case "typed": {
                    if (!(value instanceof String)) {
                        // ignore invalid option
                        Log.d("Godot", String.format("Invalid Option passed to DrawLayout with key = '%s'", key));
                        continue;
                    }
                    String v = (String) value;
                    type = v;
                }
                default:
                    Log.i("Godot", String.format("Ignoring option passed to DrawLayout with key = '%s'", key));
            }

        }
        Log.i("Godot", String.format("Created Layout with (l=%d,t=%d,w=%d,h=%d)", left, top, width, height));
    }

    public void configureTarget(View target) {
//        Log.i("godot", String.format("configuring View with [%d,%d,%d,%d]"));
        FrameLayout.LayoutParams layoutParams=new FrameLayout.LayoutParams(width, height);
        layoutParams.leftMargin = left;
        layoutParams.topMargin = top;

        target.setLayoutParams(layoutParams);
    }

}
