package com.goomsdk.util;

import java.util.ArrayList;
import java.util.List;
import java.util.HashMap;

import us.zoom.sdk.ZoomVideoSDK;
import us.zoom.sdk.ZoomVideoSDKSession;
import us.zoom.sdk.ZoomVideoSDKUser;



public class UserHelper {
    public static List<ZoomVideoSDKUser> getAllUsers() {
        List<ZoomVideoSDKUser> userList = new ArrayList<>();
        ZoomVideoSDKSession sdkSession = ZoomVideoSDK.getInstance().getSession();
        if (sdkSession == null) {
            return userList;
        }
        if (sdkSession.getMySelf() != null) {
            userList.add(sdkSession.getMySelf());
        }
        userList.addAll(sdkSession.getRemoteUsers());
        return userList;
    }

    public static HashMap<String, ZoomVideoSDKUser> getAllIdentifiedUsers() {
        HashMap<String, ZoomVideoSDKUser> ret = new HashMap<>();
        ZoomVideoSDKSession sdkSession = ZoomVideoSDK.getInstance().getSession();
        if (sdkSession == null) {
            return ret;
        }
        if (sdkSession.getMySelf() != null) {
            ret.put(UserHelper.get_user_identifier(sdkSession.getMySelf()), sdkSession.getMySelf());
        }
        for(ZoomVideoSDKUser user : sdkSession.getRemoteUsers()) {
            ret.put(UserHelper.get_user_identifier(user), user);
        }
        return ret;
    }

    public static String get_user_identifier(ZoomVideoSDKUser user) {
        if (user == null) {
            // TODO : throw an error instead.
            return "";
        }
        return user.getUserName();
    }

//    public static ZoomVideoSDKUser getUserByIdentity(String identity) {
//        List<ZoomVideoSDKUser> userList = getAllUsers();
//        for userList
//    }
}
