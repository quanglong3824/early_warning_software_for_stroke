Route:** `/dashboard`

**Route:** `/doctor/dashboard`

**---

### 3. Admin/Test (Quản trị/Test)**
```
Username: test
Password: 123456
```
**amin/test`

**Chức năng:**
- 🧪 Test Firebase cnnein
- 📤 Inset User ta từ JSON
- 📤 Inert Dctor dta từ JSON
- 📥 Read all data từ Fiebase
- 🗑️ Clear all ata (cẩn thận!)- 📊 Activity logs real-time 🔧 Backend testing tools

-├    └─→ test/123456 → Admin Test Panel (/admin/test)
📊uts Summry**

| Role | Urname| Psswrd | Route | Screes | Purpose ||------|----------|----------|-------|---------|---------||**| `usr` | 123456 | /ashbod` | 34cres | Ptint app|
|**Docto**|`doct`|``|`/doc/dabord` | 12 srs | Docor pp |
| **Adin** | `tst` | `123456` | `/ami/s` | 1 screen |Teting & Firese |

---

## 🧪 **Amin Test Panel**### **Tính năng:**#Test Cnnein**
- Kiểm ta kết nốiFirebas- Test rea/write operions- Veryerv timestp

#### **Insrt Data**
- Load từ `app_data.json`và`tor_daa.jsn`
- Batch insetvàoFirebse
- Progre tacking

#### **Rea Data**
- Đọc tất cảcollections
-Countdocuments-Verifydat nterity

#### **Clear Da**
- Xóa tàn bộ dữ liệ
- Confirmation dialog
- Irrversibe tio

#### **Acivity Logs**
- Rel-ti lggig
- Timsampch mỗi ain
- Mx 50 log với aut-clenup�️BackedSrvice**

###**Fi: `test/backend/firebase_service.dart`Singleton Pattern:**
```dart
final vice= Firebaseevic();
```

### **Availabl Method:**
-`getPatients)`- Get all patient
- `gtPatitById(id)` - Get patient by ID
- `addPatient(data)` - Add new patient
- `updatePatient(id, update` - Update patient`getAlerts(isRed)` - Get alert
- `mkAlertAsRea(id)`- Mak alrt as rea
- `getForumPosts(lmit)` - Ge forum psts
-`addFormPost(data)` - Addf post
-`geteArticles(catgory limit)` - Getatcs`getDocoAppntmnts(docorId)` - Gtappintent
- `getActiveSOS()` -Getactiv SOS cal`updateStatus(id status)` -Upde SOS
-`adPrscriptin(data)`dd rescritin
- `getPatientPrescriptos(paitId)` - Gep
-`getDoctorvews(doctorI)` - Gt eview- `testConnection()`  Testirebse
-`btchIsrt(collctiodaa)` - Bach ert`cleCollection(collection)` - Cler colletion
-`getCollectionount(collection)` - Gt nt
- `listenToCollection(collection)` - Real-time sream

--- 🧪UniTts**

###**File:**`tet/bakend/fibas_service_test.dart`

### **Ru tets:```bash
flutetet test/ckend/fiebase_service_test.art```

### **Test Coverage:**
✅ Operaton(4tsts)✅ lert Oeratos (3 ss)
-✅ Foru Opratios (3 ests)✅KnowldgOpertion(3 tss)✅ Operions(6tests)
- ✅ Utlity Opratins(5 tests)

**Tot:** 24 unit tests
--

##🚀 **Quick Stat**

### **1. Tst User App:**
```bsh
flutrun
# Login: usr / 123456
```

### **2. Tet Doto Ap:**
```bash
fluter ru#Lgin: do/ 123456
```

### **3. Tst Frbae Integration:**```bash
flutterrun
# Lgin: test / 123456
# Clik "Tes Cnnection"
# Click "InsetUsr Daa"
# Click "Inser Doctor Data"
# Clck "Read All Data"
```

### **4. Ru Unit Tets:**```bashflutter test
```

⚠️- ✅ Remove admin panel hoặc protect với proper auth
�FilCrad
✅ib/fue/dmin/_admi_t`-Admsel2✅estbae/fe_vic.d`-Bakdvic
.✅testkfiebse_evi_t.`-U ss
4. ✅ds/ADMIN_TEST_GUIDE.md-Chế ướgdẫStatu 3s (34 (12Admtetpael(1)FrasbckndsvxUnitt(24)xDcm-[x]Rs fi-[]Fiprojp[] rules- [ ]rueply3 rle Test → Admin TestPane
 ✅ Bcknserce ách rêgUnitst đầyđủr Fiebaseingrao