更新日誌 (Changelog)
所有專案的顯著變更都將記錄在此文件中。
格式基於 Keep a Changelog，
版本控制遵循 Semantic Versioning。
[1.0.0] - 2025-03-14

新增

建立專案/庫/IC三層式管理架構，實現層級化的ESD設計管理
打造IC佈局編輯器，支援引腳(Pin)放置與PAD配置
完成PinManager核心模組，處理所有引腳與PAD的CRUD操作
實作ZoomableScrollView可縮放視圖元件，提升IC佈局操作體驗
新增引腳批次操作功能，支援多選與批量編輯
整合QA管理功能，便於記錄引腳設計問答資訊
建立ModernAddPinView與ModernPadEditView直覺化編輯介面
開發CellManager系統，管理與組織Cell庫資料

優化

實作現代化UI元件與表單驗證，提升用戶體驗
優化專案導航結構，使用三層式麵包屑導航
改進IC引腳資料模型與CoreData整合架構
設計自適應UI，支援iPad與iPhone不同螢幕尺寸

架構

採用MVVM架構設計，實現UI與業務邏輯分離
使用CoreData作為持久化存儲，優化資料管理
實作發布/訂閱模式，確保跨元件資料同步
建立完整的錯誤處理與資料驗證機制

文件

新增程式碼詳細註解，便於團隊協作與未來維護
編寫CHANGELOG.md以追蹤版本歷史


