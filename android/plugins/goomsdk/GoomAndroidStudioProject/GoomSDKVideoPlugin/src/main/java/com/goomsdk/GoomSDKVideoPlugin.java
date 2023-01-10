package com.goomsdk;

import org.godotengine.godot.Dictionary;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;
import org.godotengine.godot.plugin.SignalInfo;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.os.Build;
import android.util.Log;
import android.view.View;
import android.os.Handler;
import android.os.Looper;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.collection.ArraySet;
import androidx.core.app.ActivityCompat;

import com.goomsdk.util.ErrorMsgUtil;

import java.util.Set;
import java.util.HashMap;
import java.util.List;

import us.zoom.sdk.ZoomVideoSDK;
import us.zoom.sdk.ZoomVideoSDKErrors;
import us.zoom.sdk.ZoomVideoSDKInitParams;
import us.zoom.sdk.ZoomVideoSDKRawDataMemoryMode;
import us.zoom.sdk.ZoomVideoSDKDelegate;
import us.zoom.sdk.ZoomVideoSDKAudioHelper;
import us.zoom.sdk.ZoomVideoSDKAudioRawData;
import us.zoom.sdk.ZoomVideoSDKChatHelper;
import us.zoom.sdk.ZoomVideoSDKChatMessage;
import us.zoom.sdk.ZoomVideoSDKChatMessageDeleteType;
import us.zoom.sdk.ZoomVideoSDKLiveStreamHelper;
import us.zoom.sdk.ZoomVideoSDKLiveStreamStatus;
import us.zoom.sdk.ZoomVideoSDKLiveTranscriptionHelper;
import us.zoom.sdk.ZoomVideoSDKMultiCameraStreamStatus;
import us.zoom.sdk.ZoomVideoSDKNetworkStatus;
import us.zoom.sdk.ZoomVideoSDKPasswordHandler;
import us.zoom.sdk.ZoomVideoSDKPhoneFailedReason;
import us.zoom.sdk.ZoomVideoSDKPhoneStatus;
import us.zoom.sdk.ZoomVideoSDKProxySettingHandler;
import us.zoom.sdk.ZoomVideoSDKRawDataPipe;
import us.zoom.sdk.ZoomVideoSDKRecordingConsentHandler;
import us.zoom.sdk.ZoomVideoSDKRecordingStatus;
import us.zoom.sdk.ZoomVideoSDKSSLCertificateInfo;
import us.zoom.sdk.ZoomVideoSDKShareHelper;
import us.zoom.sdk.ZoomVideoSDKShareStatus;
import us.zoom.sdk.ZoomVideoSDKUser;
import us.zoom.sdk.ZoomVideoSDKUserHelper;
import us.zoom.sdk.ZoomVideoSDKVideoCanvas;
import us.zoom.sdk.ZoomVideoSDKVideoHelper;
import us.zoom.sdk.ZoomVideoSDKSessionContext;
import us.zoom.sdk.ZoomVideoSDKSession;
import us.zoom.sdk.ZoomVideoSDKAudioOption;
import us.zoom.sdk.ZoomVideoSDKVideoOption;

import com.goomsdk.util.UserHelper;

import com.goomsdk.view.CameraStackLayout;



public class GoomSDKVideoPlugin extends GodotPlugin implements ZoomVideoSDKDelegate {
    protected static final String TAG = "godot";

    private Handler mHandler = new Handler(Looper.getMainLooper());
    private CameraStackLayout layout = null; // Store the layout

    protected final static int REQUEST_VIDEO_AUDIO_CODE = 1010;

    protected final static int REQUEST_AUDIO_TEST_CODE = 1011;

    public GoomSDKVideoPlugin(Godot godot) {
        super(godot);

    }

    @UsedByGodot
    public void godotToast(String message) {
        runOnUiThread(()->{
            Toast.makeText(getActivity(), message, Toast.LENGTH_LONG).show();
        });
    }

    // create and add a new layout to Godot
    @Override
    public View onMainCreate(Activity activity) {
        layout = new CameraStackLayout(activity);
//        layout.setBackgroundColor(Color.GREEN);
        return layout;
    }

    @Override
    public void onGodotSetupCompleted() {
    }

    @UsedByGodot
    public void configureLayout(Dictionary cdict) {
        Log.i(TAG, "configureLayout called");
        runOnUiThread(() -> {
            layout.configureLayout(cdict);
        });
    }

    @NonNull
    @Override
    public String getPluginName() {
        return "GoomSDKVideoPlugin";
    }

    @UsedByGodot
    public void set_visibility(boolean is_v) {
        Log.d("godot", "set_visibility called");
        runOnUiThread(() -> {
            if(is_v) {
//                layout.setClickable(true);
                layout.setVisibility(View.VISIBLE);
            }
            else {
//                layout.setClickable(false);
                layout.setVisibility(View.INVISIBLE);
            }
        });
    }

    @UsedByGodot
    public void init() {
        runOnUiThread(() -> {
            try {
                requestPermission(REQUEST_VIDEO_AUDIO_CODE);
                initSDK();
                ZoomVideoSDK.getInstance().addListener(this);
                setup_ui();
            }
            catch (Exception e) {
                e.printStackTrace();
                Log.e("godot", e.getMessage());
                Log.e("godot", e.toString());
            }
        });
    }

    @UsedByGodot
    public void connect_session(String jwt, String ss_name, String user_name, String pwd) {
        Log.i(TAG, "connect session called");
        runOnUiThread(() -> {
            Toast.makeText(getActivity(), "joining session", Toast.LENGTH_SHORT).show();
            ZoomVideoSDKSessionContext params = new ZoomVideoSDKSessionContext();
            params.sessionName = ss_name;
            params.userName = user_name;
            params.token = jwt;
            params.sessionPassword = pwd;
            params.sessionIdleTimeoutMins = 40;

            // Setup audio options
            ZoomVideoSDKAudioOption audioOptions = new ZoomVideoSDKAudioOption();
            audioOptions.connect = true; // Auto connect to audio upon joining
            audioOptions.mute = true; // Auto mute audio upon joining
            // Setup video options
            ZoomVideoSDKVideoOption videoOptions = new ZoomVideoSDKVideoOption();
            videoOptions.localVideoOn = true; // Turn on local/self video upon joining
            // Pass options into session
            params.videoOption = videoOptions;
            params.audioOption = audioOptions;

            ZoomVideoSDKSession session = ZoomVideoSDK.getInstance().joinSession(params);
            if(session == null) {
                Log.d(TAG, "failed to create session");
                Toast.makeText(getActivity(), "failed to create session", Toast.LENGTH_SHORT).show();
            }
            else {
                Log.i(TAG, "connecting to session");
            }
        });
    }

    @UsedByGodot
    private void reload_layouts() {
        runOnUiThread(() -> {
            layout.reload_layouts();
        });
    }

    @UsedByGodot
    public void disconnect_session() {
        runOnUiThread(() -> {
            ZoomVideoSDK.getInstance().leaveSession(false);
        });
    }

    // used for layout debugging.
    @UsedByGodot
    public void add_dummy_view() {
        runOnUiThread(() -> {
            layout.add_dummy_view();
        });
    }

    private void setup_ui() {
        runOnUiThread(() -> {
//            layout.setBackgroundColor(Color.BLACK);
        });
    }

    @NonNull
    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new ArraySet<>();
        signals.add(new SignalInfo("request_permission"));
        signals.add(new SignalInfo("session_joined", String.class /*session name*/));
        signals.add(new SignalInfo("on_error", Integer.class /*error code*/));
        return signals;
    }

    protected boolean requestPermission(int code) {

        String[] permissions = new String[]{android.Manifest.permission.CAMERA,
                Manifest.permission.RECORD_AUDIO, Manifest.permission.READ_EXTERNAL_STORAGE};
        if (Build.VERSION.SDK_INT >= 31) {
            permissions = new String[]{android.Manifest.permission.CAMERA,
                    Manifest.permission.RECORD_AUDIO, Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.READ_PHONE_STATE, Manifest.permission.BLUETOOTH_CONNECT};
        }
        if (code == REQUEST_AUDIO_TEST_CODE) {
            permissions = new String[]{Manifest.permission.RECORD_AUDIO};
            if (Build.VERSION.SDK_INT >= 31) {
                permissions = new String[]{Manifest.permission.RECORD_AUDIO, Manifest.permission.READ_PHONE_STATE, Manifest.permission.BLUETOOTH_CONNECT};
            }
        }


        if (Build.VERSION.SDK_INT >= 23) {
            for (String permission : permissions) {
                if (ActivityCompat.checkSelfPermission(getActivity(), permission) != PackageManager.PERMISSION_GRANTED) {
                    ActivityCompat.requestPermissions(getActivity(), permissions, code);
                    return false;
                }
            }
            return true;
        }
        return true;
    }

    @Override
    public void onMainRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onMainRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_VIDEO_AUDIO_CODE) {
            if (Build.VERSION.SDK_INT >= 23 && (getActivity().checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
                    && getActivity().checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
                    && (Build.VERSION.SDK_INT >= 31 && getActivity().checkSelfPermission("android.permission.READ_PHONE_STATE") == PackageManager.PERMISSION_GRANTED))) {
//                onPermissionGranted();
            }
        }
    }

//    protected void onPermissionGranted() {
//        joinOrCreateSession();
//    }



    protected void initSDK() {
        ZoomVideoSDKInitParams params = new ZoomVideoSDKInitParams();
        params.domain = "https://zoom.us";
        params.logFilePrefix = "godot";
        params.enableLog = true;
        params.videoRawDataMemoryMode = ZoomVideoSDKRawDataMemoryMode.ZoomVideoSDKRawDataMemoryModeHeap;
        params.audioRawDataMemoryMode = ZoomVideoSDKRawDataMemoryMode.ZoomVideoSDKRawDataMemoryModeHeap;
        params.shareRawDataMemoryMode = ZoomVideoSDKRawDataMemoryMode.ZoomVideoSDKRawDataMemoryModeHeap;


        int ret = ZoomVideoSDK.getInstance().initialize(getActivity().getApplicationContext(), params);
        if (ret != ZoomVideoSDKErrors.Errors_Success) {
            Toast.makeText(getActivity(), ErrorMsgUtil.getMsgByErrorCode(ret), Toast.LENGTH_LONG).show();
        }else {
            //((TextView) findViewById(R.id.text_version)).setText(getString(R.string.launch_setting_version, ZoomVideoSDK.getInstance().getSDKVersion()));
        }
    }

    @Override
    public void onSessionJoin() {
        Log.i(TAG, "session joined");
        runOnUiThread(() -> {
        for (ZoomVideoSDKUser user : UserHelper.getAllUsers()) {
            userJoined(user);
        }
        ZoomVideoSDKSession session = ZoomVideoSDK.getInstance().getSession();

        String sessionName = session.getSessionName();
        Toast.makeText(getActivity(), "joined session", Toast.LENGTH_LONG).show();
        emitSignal("session_joined", sessionName);
        });
    }

    @Override
    public void onSessionLeave() {
        Log.i(TAG, "left session");
        runOnUiThread(() -> {
            Toast.makeText(getActivity(), "left session", Toast.LENGTH_LONG).show();
            layout.clear();
        });
    }

    @Override
    public void onError(int errorCode) {
        Log.e(TAG, "error");
        runOnUiThread(() -> {
            Toast.makeText(getActivity(), ErrorMsgUtil.getMsgByErrorCode(errorCode) + ". Error code: "+errorCode, Toast.LENGTH_LONG).show();

//            emitSignal("on_error", new Integer(errorCode));
        });
    }

    @Override
    public void onUserJoin(ZoomVideoSDKUserHelper userHelper, List<ZoomVideoSDKUser> userList) {
        for (ZoomVideoSDKUser user : userList) {
            Log.i(TAG, "user :" +  user.getUserName() + "joined");
        }
        runOnUiThread(() -> {
            for (ZoomVideoSDKUser user : userList) {
                // Access current user's info here
                Toast.makeText(getActivity(), "user :" +  user.getUserName() + "joined", Toast.LENGTH_LONG).show();
                userJoined(user);
            }
        });

    }

    private void userJoined(ZoomVideoSDKUser user) {
        layout.addUser(user);
    }

    @Override
    public void onUserLeave(ZoomVideoSDKUserHelper userHelper, List<ZoomVideoSDKUser> userList) {
        runOnUiThread(() -> {
            for (ZoomVideoSDKUser user : userList) {
                // Access current user's info here
                userLeft(user);
            }
        });
    }

    private void userLeft(ZoomVideoSDKUser user) {
        layout.removeUser(user);
    }

    @Override
    public void onUserVideoStatusChanged(ZoomVideoSDKVideoHelper videoHelper, List<ZoomVideoSDKUser> userList) {

    }

    @Override
    public void onUserAudioStatusChanged(ZoomVideoSDKAudioHelper audioHelper, List<ZoomVideoSDKUser> userList) {

    }

    @Override
    public void onUserShareStatusChanged(ZoomVideoSDKShareHelper shareHelper, ZoomVideoSDKUser userInfo, ZoomVideoSDKShareStatus status) {

    }

    @Override
    public void onLiveStreamStatusChanged(ZoomVideoSDKLiveStreamHelper liveStreamHelper, ZoomVideoSDKLiveStreamStatus status) {

    }

    @Override
    public void onChatNewMessageNotify(ZoomVideoSDKChatHelper chatHelper, ZoomVideoSDKChatMessage messageItem) {

    }

    @Override
    public void onChatDeleteMessageNotify(ZoomVideoSDKChatHelper chatHelper, String msgID, ZoomVideoSDKChatMessageDeleteType deleteBy) {

    }

    @Override
    public void onUserHostChanged(ZoomVideoSDKUserHelper userHelper, ZoomVideoSDKUser userInfo) {

    }

    @Override
    public void onUserManagerChanged(ZoomVideoSDKUser user) {

    }

    @Override
    public void onUserNameChanged(ZoomVideoSDKUser user) {

    }

    @Override
    public void onUserActiveAudioChanged(ZoomVideoSDKAudioHelper audioHelper, List<ZoomVideoSDKUser> list) {

    }

    @Override
    public void onSessionNeedPassword(ZoomVideoSDKPasswordHandler handler) {

    }

    @Override
    public void onSessionPasswordWrong(ZoomVideoSDKPasswordHandler handler) {

    }

    @Override
    public void onMixedAudioRawDataReceived(ZoomVideoSDKAudioRawData rawData) {

    }

    @Override
    public void onOneWayAudioRawDataReceived(ZoomVideoSDKAudioRawData rawData, ZoomVideoSDKUser user) {

    }

    @Override
    public void onShareAudioRawDataReceived(ZoomVideoSDKAudioRawData rawData) {

    }

    @Override
    public void onCommandReceived(ZoomVideoSDKUser sender, String strCmd) {

    }

    @Override
    public void onCommandChannelConnectResult(boolean isSuccess) {

    }

    @Override
    public void onCloudRecordingStatus(ZoomVideoSDKRecordingStatus status, ZoomVideoSDKRecordingConsentHandler handler) {

    }

    @Override
    public void onHostAskUnmute() {

    }

    @Override
    public void onInviteByPhoneStatus(ZoomVideoSDKPhoneStatus status, ZoomVideoSDKPhoneFailedReason reason) {

    }

    @Override
    public void onMultiCameraStreamStatusChanged(ZoomVideoSDKMultiCameraStreamStatus status, ZoomVideoSDKUser user, ZoomVideoSDKRawDataPipe videoPipe) {
    }

    public void onMultiCameraStreamStatusChanged(ZoomVideoSDKMultiCameraStreamStatus status, ZoomVideoSDKUser user, ZoomVideoSDKVideoCanvas canvas) {

    }

    @Override
    public void onLiveTranscriptionStatus(ZoomVideoSDKLiveTranscriptionHelper.ZoomVideoSDKLiveTranscriptionStatus status) {

    }

    @Override
    public void onLiveTranscriptionMsgReceived(String ltMsg, ZoomVideoSDKUser pUser, ZoomVideoSDKLiveTranscriptionHelper.ZoomVideoSDKLiveTranscriptionOperationType type) {

    }

    @Override
    public void onLiveTranscriptionMsgError(ZoomVideoSDKLiveTranscriptionHelper.ILiveTranscriptionLanguage spokenLanguage, ZoomVideoSDKLiveTranscriptionHelper.ILiveTranscriptionLanguage transcriptLanguage) {

    }

    @Override
    public void onProxySettingNotification(ZoomVideoSDKProxySettingHandler handler) {

    }

    @Override
    public void onSSLCertVerifiedFailNotification(ZoomVideoSDKSSLCertificateInfo info) {

    }

    @Override
    public void onCameraControlRequestResult(ZoomVideoSDKUser user, boolean isApproved) {

    }

    @Override
    public void onUserVideoNetworkStatusChanged(ZoomVideoSDKNetworkStatus status, ZoomVideoSDKUser user) {

    }

    @Override
    public void onUserRecordingConsent(ZoomVideoSDKUser user) {

    }

}