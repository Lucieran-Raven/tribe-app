import { initializeApp } from "https://www.gstatic.com/firebasejs/11.0.2/firebase-app.js";
import { getAuth, GoogleAuthProvider, signInWithPopup } from "https://www.gstatic.com/firebasejs/11.0.2/firebase-auth.js";
import { getFunctions, httpsCallable } from "https://www.gstatic.com/firebasejs/11.0.2/firebase-functions.js";

const firebaseConfig = window.TRIBE_FIREBASE_CONFIG;
const status = document.querySelector("#status");
if (!firebaseConfig) {
  status.textContent = "Admin setup required: define window.TRIBE_FIREBASE_CONFIG before app.js loads.";
}
const app = firebaseConfig ? initializeApp(firebaseConfig) : null;
const auth = app ? getAuth(app) : null;
const functions = app ? getFunctions(app) : null;
const login = document.querySelector("#login"), panel = document.querySelector("#app");

document.querySelector("#signIn").onclick = async () => {
  if (!auth) return;
  await signInWithPopup(auth, new GoogleAuthProvider());
  login.hidden = true; panel.hidden = false;
};
const call = async (name, data) => {
  try { status.textContent = JSON.stringify(await httpsCallable(functions, name)(data), null, 2); }
  catch (e) { status.textContent = e.message; }
};
document.querySelector("#deletePost").onclick=()=>call("deletePost",{rantId:document.querySelector("#postId").value});
document.querySelector("#deleteReply").onclick=()=>call("deleteReply",{rantId:document.querySelector("#rantId").value,replyId:document.querySelector("#replyId").value});
document.querySelector("#banUser").onclick=()=>call("banUser",{userId:document.querySelector("#userId").value,banned:document.querySelector("#ban").checked});
document.querySelector("#announce").onclick=()=>call("createAnnouncement",{title:document.querySelector("#announcementTitle").value,body:document.querySelector("#announcementBody").value});


document.querySelector("#refresh").onclick = async () => {
  try {
    const result = await httpsCallable(functions, "getAdminData")();
    document.querySelector("#data").textContent = JSON.stringify(result.data, null, 2);
  } catch (e) { status.textContent = e.message; }
};
