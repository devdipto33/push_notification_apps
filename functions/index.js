const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * 1. Register or update a receiver device via secure Cloud Function.
 * - Authenticates caller (supports Anonymous Auth for receiver devices)
 * - Validates deviceId and fcmToken
 * - Prevents duplicate registrations across devices with same token
 * - Persists device record in Cloud Firestore 'devices' collection
 */
exports.registerDevice = onCall(
  {
    cors: true,
    maxInstances: 10,
  },
  async (request) => {
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError(
        "unauthenticated",
        "Authentication required: Please ensure Firebase Auth is initialized."
      );
    }

    const callerUid = request.auth.uid;
    const { deviceId, fcmToken, deviceName, platform, osVersion, appVersion } =
      request.data || {};

    if (!deviceId || typeof deviceId !== "string" || deviceId.trim().length === 0) {
      throw new HttpsError("invalid-argument", "A valid deviceId is required.");
    }
    if (!fcmToken || typeof fcmToken !== "string" || fcmToken.trim().length === 0) {
      throw new HttpsError("invalid-argument", "A valid fcmToken is required.");
    }

    const cleanDeviceId = deviceId.trim();
    const cleanToken = fcmToken.trim();

    // Deduplication check: if another device record had this identical token, deactivate it
    const duplicates = await db
      .collection("devices")
      .where("fcmToken", "==", cleanToken)
      .get();

    const batch = db.batch();

    duplicates.forEach((doc) => {
      if (doc.id !== cleanDeviceId) {
        console.log(`[registerDevice] Deactivating duplicate device ${doc.id} with same token`);
        batch.update(doc.ref, {
          isActive: false,
          tokenReplacedBy: cleanDeviceId,
          lastSeenAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    });

    // Save or update current device
    const deviceRef = db.collection("devices").doc(cleanDeviceId);
    const existingSnap = await deviceRef.get();

    const deviceData = {
      deviceId: cleanDeviceId,
      fcmToken: cleanToken,
      deviceName:
        deviceName && typeof deviceName === "string"
          ? deviceName.trim()
          : "Android Device",
      platform:
        platform && typeof platform === "string" ? platform.trim() : "Android",
      osVersion:
        osVersion && typeof osVersion === "string"
          ? osVersion.trim()
          : "Unknown",
      appVersion:
        appVersion && typeof appVersion === "string"
          ? appVersion.trim()
          : "1.0.0",
      isActive: true,
      ownerUid: callerUid,
      lastSeenAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (!existingSnap.exists) {
      deviceData.registeredAt = admin.firestore.FieldValue.serverTimestamp();
      batch.set(deviceRef, deviceData);
    } else {
      batch.update(deviceRef, deviceData);
    }

    await batch.commit();
    console.log(
      `[registerDevice] Device ${cleanDeviceId} successfully saved to Firestore 'devices'`
    );

    return {
      success: true,
      deviceId: cleanDeviceId,
      message: "Device registered successfully in Cloud Firestore.",
    };
  }
);

/**
 * 2. Update device token when FCM token refreshes.
 */
exports.updateDeviceToken = onCall(
  {
    cors: true,
    maxInstances: 10,
  },
  async (request) => {
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError(
        "unauthenticated",
        "Authentication required to update device token."
      );
    }

    const { deviceId, fcmToken } = request.data || {};
    if (!deviceId || !fcmToken) {
      throw new HttpsError(
        "invalid-argument",
        "deviceId and fcmToken are required."
      );
    }

    const cleanDeviceId = deviceId.trim();
    const cleanToken = fcmToken.trim();

    // Invalidate duplicate token entries on other devices
    const duplicates = await db
      .collection("devices")
      .where("fcmToken", "==", cleanToken)
      .get();

    const batch = db.batch();
    duplicates.forEach((doc) => {
      if (doc.id !== cleanDeviceId) {
        batch.update(doc.ref, {
          isActive: false,
          tokenReplacedBy: cleanDeviceId,
          lastSeenAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    });

    const deviceRef = db.collection("devices").doc(cleanDeviceId);
    batch.set(
      deviceRef,
      {
        deviceId: cleanDeviceId,
        fcmToken: cleanToken,
        isActive: true,
        lastSeenAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await batch.commit();
    console.log(`[updateDeviceToken] Token updated for ${cleanDeviceId}`);

    return { success: true, message: "Device token refreshed successfully." };
  }
);

/**
 * 3. Fetch registered devices (restricted to authorized senders).
 */
exports.getRegisteredDevices = onCall(
  {
    cors: true,
    maxInstances: 10,
  },
  async (request) => {
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError(
        "unauthenticated",
        "Authentication required to view registered devices."
      );
    }

    const callerUid = request.auth.uid;
    const senderDoc = await db.collection("authorized_senders").doc(callerUid).get();

    let isAuthorized = senderDoc.exists && senderDoc.data()?.isAuthorized === true;
    if (!isAuthorized) {
      const existingSenders = await db.collection("authorized_senders").limit(1).get();
      if (existingSenders.empty) {
        await db.collection("authorized_senders").doc(callerUid).set({
          uid: callerUid,
          isAuthorized: true,
          role: "admin_sender",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          note: "Auto-authorized developer account",
        });
        isAuthorized = true;
      }
    }

    if (!isAuthorized) {
      throw new HttpsError(
        "permission-denied",
        "Access denied: Only authorized senders can view the device list."
      );
    }

    const snapshot = await db
      .collection("devices")
      .orderBy("lastSeenAt", "desc")
      .get();

    const devices = [];
    snapshot.forEach((doc) => {
      const d = doc.data();
      devices.push({
        deviceId: doc.id,
        deviceName: d.deviceName || "Unknown Device",
        platform: d.platform || "Android",
        osVersion: d.osVersion || "Unknown",
        appVersion: d.appVersion || "1.0.0",
        isActive: d.isActive !== false,
        registeredAt: d.registeredAt?.toDate()?.toISOString() || new Date().toISOString(),
        lastSeenAt: d.lastSeenAt?.toDate()?.toISOString() || new Date().toISOString(),
        fcmToken: d.fcmToken || "",
      });
    });

    return { success: true, devices };
  }
);

/**
 * 4. Secure server-side push notification dispatch via Firebase Admin SDK.
 */
exports.sendPushNotification = onCall(
  {
    cors: true,
    maxInstances: 10,
  },
  async (request) => {
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError(
        "unauthenticated",
        "Authentication required: Please sign in before sending notifications."
      );
    }

    const callerUid = request.auth.uid;
    console.log(`[sendPushNotification] Request from caller: ${callerUid}`);

    // Verify sender authorization
    const senderDoc = await db.collection("authorized_senders").doc(callerUid).get();

    if (!senderDoc.exists || senderDoc.data()?.isAuthorized !== true) {
      const existingSenders = await db.collection("authorized_senders").limit(1).get();
      if (existingSenders.empty) {
        console.log(`[sendPushNotification] Bootstrapping first user ${callerUid} as authorized sender.`);
        await db.collection("authorized_senders").doc(callerUid).set({
          uid: callerUid,
          isAuthorized: true,
          role: "admin_sender",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          note: "Auto-authorized developer account",
        });
      } else {
        throw new HttpsError(
          "permission-denied",
          "Access denied: You are not an authorized notification sender."
        );
      }
    }

    // Validate request data
    const { title, body, targetDeviceIds } = request.data || {};

    if (!title || typeof title !== "string" || title.trim().length === 0) {
      throw new HttpsError("invalid-argument", "Message title cannot be empty.");
    }
    if (!body || typeof body !== "string" || body.trim().length === 0) {
      throw new HttpsError("invalid-argument", "Message body cannot be empty.");
    }
    if (!Array.isArray(targetDeviceIds) || targetDeviceIds.length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "Please select at least one recipient device."
      );
    }

    // Retrieve FCM tokens for the selected device IDs
    const tokens = [];
    const tokenToDeviceIdMap = new Map();

    for (const deviceId of targetDeviceIds) {
      try {
        const docSnap = await db.collection("devices").doc(deviceId).get();
        if (docSnap.exists) {
          const data = docSnap.data();
          const token = data?.fcmToken;
          if (token && typeof token === "string" && token.trim().length > 0) {
            tokens.push(token);
            tokenToDeviceIdMap.set(token, deviceId);
          }
        }
      } catch (err) {
        console.error(`Error reading device ${deviceId}:`, err);
      }
    }

    if (tokens.length === 0) {
      return {
        success: false,
        delivered: 0,
        failed: targetDeviceIds.length,
        message: "None of the selected devices have active FCM tokens.",
      };
    }

    // Send FCM Multicast via Admin SDK
    const messagePayload = {
      tokens: tokens,
      notification: {
        title: title.trim(),
        body: body.trim(),
      },
      data: {
        title: title.trim(),
        body: body.trim(),
        sentAt: new Date().toISOString(),
        senderUid: callerUid,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "simple_push_channel",
          sound: "default",
          priority: "high",
          defaultVibrateTimings: true,
        },
      },
    };

    console.log(`[sendPushNotification] Sending multicast to ${tokens.length} tokens...`);
    const batchResponse = await admin.messaging().sendEachForMulticast(messagePayload);
    console.log(
      `[sendPushNotification] Results: ${batchResponse.successCount} success, ${batchResponse.failureCount} failed.`
    );

    // Prune / mark invalid tokens
    const staleDeviceIds = [];
    batchResponse.responses.forEach((resp, index) => {
      if (!resp.success) {
        const errorCode = resp.error?.code;
        console.warn(`Token error at index ${index}: ${errorCode}`, resp.error?.message);
        if (
          errorCode === "messaging/invalid-registration-token" ||
          errorCode === "messaging/registration-token-not-registered"
        ) {
          const badToken = tokens[index];
          const devId = tokenToDeviceIdMap.get(badToken);
          if (devId) staleDeviceIds.push(devId);
        }
      }
    });

    for (const staleId of staleDeviceIds) {
      try {
        await db.collection("devices").doc(staleId).update({
          isActive: false,
          lastError: "FCM token expired or invalid",
          lastSeenAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (err) {
        console.error(`Failed to update stale device ${staleId}:`, err);
      }
    }

    return {
      success: batchResponse.successCount > 0,
      delivered: batchResponse.successCount,
      failed: batchResponse.failureCount,
      message: `Notification delivered to ${batchResponse.successCount} device(s).`,
    };
  }
);
