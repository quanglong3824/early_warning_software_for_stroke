' ============================================
' MACRO ĐỊNH DẠNG BÁO CÁO ĐỒ ÁN TỰ ĐỘNG
' Dùng cho Microsoft Word 2020+ macOS
' ============================================
'
' CÁCH SỬ DỤNG TRÊN macOS:
'
' Bước 1: Mở Word và tạo document mới
'
' Bước 2: Vào Tools > Macro > Visual Basic Editor
'         (hoặc nhấn Option + F11)
'
' Bước 3: Trong VBA Editor:
'         - Click Insert > Module
'         - Copy toàn bộ code này vào
'
' Bước 4: Đóng VBA Editor (Command + Q hoặc đóng cửa sổ)
'
' Bước 5: Chạy macro:
'         - Vào Tools > Macro > Macros
'         - Chọn "FormatAllDocument" và click Run
'
' LƯU Ý QUAN TRỌNG cho macOS:
' - Lưu file dạng .docm (Word Macro-Enabled Document)
' - Nếu macro không chạy, vào:
'   Word > Preferences > Security & Privacy
'   Bật "Enable all macros"
'
' ============================================

Sub SetupPageLayout()
    ' ===== 1. THIẾT LẬP TRANG A4 =====
    With ActiveDocument.PageSetup
        .PaperSize = wdPaperA4
        .TopMargin = CentimetersToPoints(2.5)
        .BottomMargin = CentimetersToPoints(2.5)
        .LeftMargin = CentimetersToPoints(3)
        .RightMargin = CentimetersToPoints(2)
        .HeaderDistance = CentimetersToPoints(1.5)
        .FooterDistance = CentimetersToPoints(1.5)
    End With
    MsgBox "Da thiet lap Page Layout thanh cong!"
End Sub

Sub SetupStyles()
    ' ===== 2. THIẾT LẬP STYLES =====
    Dim doc As Document
    Set doc = ActiveDocument
    
    ' Style cho nội dung thường (Normal)
    With doc.Styles("Normal").Font
        .Name = "Times New Roman"
        .Size = 13
    End With
    With doc.Styles("Normal").ParagraphFormat
        .LineSpacingRule = wdLineSpace1pt5
        .SpaceBefore = 6
        .SpaceAfter = 6
        .FirstLineIndent = CentimetersToPoints(1)
        .Alignment = wdAlignParagraphJustify
    End With
    
    ' Style Heading 1 (PHẦN 1, PHẦN 2...)
    With doc.Styles("Heading 1").Font
        .Name = "Times New Roman"
        .Size = 16
        .Bold = True
        .AllCaps = True
    End With
    With doc.Styles("Heading 1").ParagraphFormat
        .LineSpacingRule = wdLineSpace1pt5
        .SpaceBefore = 12
        .SpaceAfter = 12
        .Alignment = wdAlignParagraphCenter
        .FirstLineIndent = 0
        .PageBreakBefore = True
    End With
    
    ' Style Heading 2 (1.1, 1.2, 2.1...)
    With doc.Styles("Heading 2").Font
        .Name = "Times New Roman"
        .Size = 14
        .Bold = True
        .AllCaps = False
    End With
    With doc.Styles("Heading 2").ParagraphFormat
        .LineSpacingRule = wdLineSpace1pt5
        .SpaceBefore = 12
        .SpaceAfter = 6
        .Alignment = wdAlignParagraphLeft
        .FirstLineIndent = 0
    End With
    
    ' Style Heading 3 (1.1.1, 1.1.2...)
    With doc.Styles("Heading 3").Font
        .Name = "Times New Roman"
        .Size = 13
        .Bold = True
        .AllCaps = False
    End With
    With doc.Styles("Heading 3").ParagraphFormat
        .LineSpacingRule = wdLineSpace1pt5
        .SpaceBefore = 6
        .SpaceAfter = 6
        .Alignment = wdAlignParagraphLeft
        .FirstLineIndent = 0
    End With
    
    MsgBox "Da thiet lap Styles thanh cong!"
End Sub

Sub SetupHeaderFooter()
    ' ===== 3. THIẾT LẬP SỐ TRANG =====
    Dim sec As Section
    
    For Each sec In ActiveDocument.Sections
        With sec.Footers(wdHeaderFooterPrimary)
            .Range.Delete
            .Range.Fields.Add Range:=.Range, Type:=wdFieldPage
            .Range.ParagraphFormat.Alignment = wdAlignParagraphCenter
            .Range.Font.Name = "Times New Roman"
            .Range.Font.Size = 11
        End With
    Next sec
    
    MsgBox "Da thiet lap so trang thanh cong!"
End Sub

Sub FormatSelectedAsTitle()
    ' ===== CHỌN TEXT TRƯỚC, RỒI CHẠY MACRO NÀY =====
    ' Dùng cho: PHẦN 1, PHẦN 2...
    With Selection.Font
        .Name = "Times New Roman"
        .Size = 16
        .Bold = True
        .AllCaps = True
    End With
    With Selection.ParagraphFormat
        .Alignment = wdAlignParagraphCenter
        .SpaceBefore = 12
        .SpaceAfter = 12
        .FirstLineIndent = 0
    End With
End Sub

Sub FormatSelectedAsHeading2()
    ' ===== CHỌN TEXT TRƯỚC, RỒI CHẠY MACRO NÀY =====
    ' Dùng cho: 1.1, 1.2, 2.1...
    With Selection.Font
        .Name = "Times New Roman"
        .Size = 14
        .Bold = True
    End With
    With Selection.ParagraphFormat
        .Alignment = wdAlignParagraphLeft
        .SpaceBefore = 12
        .SpaceAfter = 6
        .FirstLineIndent = 0
    End With
End Sub

Sub FormatSelectedAsHeading3()
    ' ===== CHỌN TEXT TRƯỚC, RỒI CHẠY MACRO NÀY =====
    ' Dùng cho: 1.1.1, 1.1.2...
    With Selection.Font
        .Name = "Times New Roman"
        .Size = 13
        .Bold = True
    End With
    With Selection.ParagraphFormat
        .Alignment = wdAlignParagraphLeft
        .SpaceBefore = 6
        .SpaceAfter = 6
        .FirstLineIndent = 0
    End With
End Sub

Sub FormatSelectedAsNormal()
    ' ===== CHỌN TEXT TRƯỚC, RỒI CHẠY MACRO NÀY =====
    ' Dùng cho: Nội dung văn bản thường
    With Selection.Font
        .Name = "Times New Roman"
        .Size = 13
        .Bold = False
    End With
    With Selection.ParagraphFormat
        .Alignment = wdAlignParagraphJustify
        .LineSpacingRule = wdLineSpace1pt5
        .SpaceBefore = 6
        .SpaceAfter = 6
        .FirstLineIndent = CentimetersToPoints(1)
    End With
End Sub

Sub FormatAllDocument()
    ' ===== CHẠY MACRO NÀY ĐẦU TIÊN =====
    ' Setup tất cả: Page, Styles, Header/Footer
    Call SetupPageLayout
    Call SetupStyles
    Call SetupHeaderFooter
    MsgBox "HOAN THANH! Document da duoc thiet lap dinh dang chuan bao cao."
End Sub

Sub CreateTitlePage()
    ' ===== TẠO TRANG BÌA MẪU =====
    Dim rng As Range
    Set rng = ActiveDocument.Range(0, 0)
    
    rng.InsertAfter "BỘ GIÁO DỤC VÀ ĐÀO TẠO" & vbCr
    rng.InsertAfter "TRƯỜNG ĐẠI HỌC..." & vbCr
    rng.InsertAfter "KHOA CÔNG NGHỆ THÔNG TIN" & vbCr & vbCr & vbCr
    rng.InsertAfter "ĐỒ ÁN TỐT NGHIỆP" & vbCr & vbCr
    rng.InsertAfter "HỆ THỐNG CẢNH BÁO SỚM ĐỘT QUỴ" & vbCr
    rng.InsertAfter "SEWS - STROKE EARLY WARNING SYSTEM" & vbCr & vbCr & vbCr
    rng.InsertAfter "Sinh viên thực hiện: Nguyễn Quang Long" & vbCr
    rng.InsertAfter "MSSV: ..." & vbCr
    rng.InsertAfter "Giảng viên hướng dẫn: ..." & vbCr & vbCr & vbCr
    rng.InsertAfter "TP. Hồ Chí Minh, tháng 12 năm 2024" & vbCr
    
    rng.Font.Name = "Times New Roman"
    rng.ParagraphFormat.Alignment = wdAlignParagraphCenter
    
    rng.InsertBreak Type:=wdPageBreak
    
    MsgBox "Da tao trang bia!"
End Sub

' ============================================
' HƯỚNG DẪN SỬ DỤNG NHANH (macOS):
' ============================================
' 1. FormatAllDocument  - Chạy ĐẦU TIÊN để setup
' 2. CreateTitlePage    - Tạo trang bìa mẫu
' 3. FormatSelectedAsTitle    - Chọn text > format PHẦN
' 4. FormatSelectedAsHeading2 - Chọn text > format 1.1
' 5. FormatSelectedAsHeading3 - Chọn text > format 1.1.1
' 6. FormatSelectedAsNormal   - Chọn text > format nội dung
'
' PHÍM TẮT (tùy chọn):
' Vào Tools > Customize Keyboard để gán phím tắt
' Ví dụ: Command+1 cho Title, Command+2 cho Heading2...
' ============================================
