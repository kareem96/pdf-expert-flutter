# PDF Expert - Future Feature Ideas (Drafts & Pins)

This document contains a curated list of high-level, premium features planned for future development. These were brainstormed as potential "Killer Features" to elevate the application.

## 1. "Redaction Tool" (Alat Sensor / Penghapus Data Rahasia)
- **Function:** A dedicated tool (e.g., a Black Marker icon) to block out or redact sensitive text areas (like ID numbers, bank accounts, addresses).
- **Technical Challenge (High):** Building a true redaction tool is more than drawing a black box over the PDF. If exported, users could still "copy-paste" the original underlying text. The challenge involves parsing the PDF's text layer and mathematically wiping out/destroying the original character structures from the database permanently before drawing the black box.

## 2. "Page Manager" (Manajemen Ulang Halaman)
- **Function:** A UI mode that transforms the viewer into a Grid of small thumbnails showing all PDF pages.
- **Technical Challenge (Medium-High):** Implementing a robust Drag-and-Drop system to reorder pages (e.g., swapping Page 5 with Page 1). Additionally, injecting the capability to Rotate pages 90 degrees, extract/split single pages into new PDFs, or Delete specific pages entirely before saving the final document.

## 3. "Smart Freehand Pen" (Coretan Kuas Tinta Bebas)
- **Function:** A mandatory feature for teachers or manual annotators. Allows users to freely draw or scribble on the PDF pages using their fingers or a stylus, featuring natural ink textures and dynamic brush thickness.
- **Technical Challenge (Advanced):** This cannot rely on simple image overlays. It requires recording thousands of real-time touch coordinate points (`GestureDetector.onPanUpdate`), converting them into smooth mathematical Vector Paths (Bezier Curves) to avoid jagged edges, and then translating these into native Syncfusion Graphics Paths within the PDF's underlying structure.

## 4. "Global Watermark Injector" (Pencap Tanda Air Sekali Klik)
- **Function:** A security feature where users can click "Watermark", type a confidential company name, set opacity (e.g., 30%), and instantly protect their document.
- **Technical Challenge (Medium):** The application must execute a high-speed looping engine that automatically injects a diagonally slanted text overlay across every single page (which could be 100+ pages) without maxing out device memory or causing UI stuttering.
