--1--
/*
Müþteri Özeti:
• Müþteri Adý
• Adres
• Web Sitesi
• Kredi Limiti
• Toplam Sipariþ Tutarý
• Bekleyen Sipariþ Tutarý
• Ýptal Edilmiþ Sipariþ Tutarý
*Hiç sipariþi olmayan müþteriler de listede bulunmalýdýr
*/

WITH
	/*Common Table Expression kullanarak sipariþ durumuna göre
	filtrelediðim satýrlarý farklý birer tablo gibi kullandým.*/
    TOPLAM_SIPARIS AS (
    SELECT
    CUSTOMERS.NAME,
    SUM(order_items.quantity*order_items.unit_price) AS TOPLAM
    FROM order_items
    FULL JOIN ORDERS ON ORDERS.order_id=order_items.order_id
    JOIN CUSTOMERS ON CUSTOMERS.customer_id=ORDERS.customer_id
	--Orders ve Customers tablolarýný JOIN kullanarak birleþtirdim
    GROUP BY CUSTOMERS.NAME),  
    BEKLEYEN_SIPARIS AS (
    SELECT
    CUSTOMERS.NAME,
    SUM(order_items.quantity*order_items.unit_price) AS BEKLEYEN_TOPLAM
    FROM order_items
    FULL JOIN ORDERS ON ORDERS.order_id=order_items.order_id 
    JOIN CUSTOMERS ON CUSTOMERS.customer_id=ORDERS.customer_id
    WHERE ORDERS.STATUS='Pending'
    GROUP BY CUSTOMERS.NAME),
    IPTAL_SIPARIS AS (
    SELECT
    CUSTOMERS.NAME,
    SUM(order_items.quantity*order_items.unit_price) AS IPTAL_TOPLAM
    FROM order_items
    FULL JOIN ORDERS ON ORDERS.order_id=order_items.order_id
    FULL JOIN CUSTOMERS ON CUSTOMERS.customer_id=ORDERS.customer_id
    WHERE ORDERS.STATUS='Canceled'
    GROUP BY CUSTOMERS.NAME)
	/*Sorgu sonucunda görmek istediðim satýrlarý listeledim.*/
SELECT CUSTOMERS.NAME AS MUSTERIADI,
    CUSTOMERS.ADDRESS AS ADRES,
    CUSTOMERS.website AS WEBSITESI,
    CUSTOMERS.credit_limit AS KREDILIMITI,
    TOPLAM_SIPARIS.TOPLAM AS TOPLAM_SIPARIS_TUTARI,
    BEKLEYEN_SIPARIS.BEKLEYEN_TOPLAM AS BEKLEYEN_SIPARIS_TUTARI,
    IPTAL_SIPARIS.IPTAL_TOPLAM AS IPTAL_SIPARIS_TUTARI
FROM customers
	/*Oluþturduðum common table expressionlarý birleþtirdim.*/
    LEFT JOIN BEKLEYEN_SIPARIS ON BEKLEYEN_SIPARIS.NAME=CUSTOMERS.NAME
    LEFT JOIN IPTAL_SIPARIS ON IPTAL_SIPARIS.NAME=CUSTOMERS.NAME
    LEFT JOIN TOPLAM_SIPARIS ON TOPLAM_SIPARIS.NAME=CUSTOMERS.NAME
ORDER BY 5 DESC-- Sorguyu MUSTERIADI kolonuna göre sýraladým.    


--2--
/*
Müþteri Kredi Özeti
• Müþteri Adý
• Kredi Limiti
• Bekleyen Sipariþ Tutarý
• Limit Aþýmý(Evet/Hayýr) : Müþterin toplam bekleyen sipariþ tutarlarý toplamý Kredi 
limitini aþýyorsa Evet, aþmýyorsa Hayýr.
 *Hiç sipariþi olmayan müþteriler de listede bulunmalýdýr
 */

WITH BEKLEYEN_SIPARIS_TUTARI AS (SELECT
         CUSTOMERS.NAME,
         SUM(order_items.quantity*order_items.unit_price) AS BEKLEYEN_TOPLAM
         FROM order_items
         FULL JOIN ORDERS ON ORDERS.ORDER_ID=ORDER_ITEMS.ORDER_ID
         FULL JOIN CUSTOMERS ON CUSTOMERS.CUSTOMER_ID=ORDERS.CUSTOMER_ID
         WHERE ORDERS.STATUS='Pending'
         GROUP BY CUSTOMERS.NAME
         ORDER BY CUSTOMERS.NAME)
SELECT 
CUSTOMERS.NAME AS MUSTERIADI,
CUSTOMERS.CREDIT_LIMIT AS KREDILIMITI,
BEKLEYEN_SIPARIS_TUTARI.BEKLEYEN_TOPLAM,
CASE
    WHEN BEKLEYEN_SIPARIS_TUTARI.BEKLEYEN_TOPLAM>CUSTOMERS.CREDIT_LIMIT THEN 'Evet'
    ELSE 'Hayýr'
    END AS DURUM
FROM CUSTOMERS
FULL JOIN BEKLEYEN_SIPARIS_TUTARI ON BEKLEYEN_SIPARIS_TUTARI.NAME=CUSTOMERS.NAME
ORDER BY 1

       

--3--
/*
Sipariþ Özeti
• Sipariþ No
• Müþteri Adý
• Müþteri Kontak Adý
• Sipariþin Satýþ Temsilcisi Adý
• Sipariþteki Toplam Ürün Sayýsý
• Sipariþteki Toplam Ürün Çeþidi Sayýsý
• Sipariþ Statüsü
• Sipariþ Tutarý
*/
WITH TOPLAM_URUN_SAYISI AS (SELECT
    ORDERS.ORDER_ID,
    SUM(ORDER_ITEMS.QUANTITY) as URUN_SAYISI
    FROM ORDERS
    JOIN ORDER_ITEMS ON ORDERS.ORDER_ID=ORDER_ITEMS.ORDER_ID
    GROUP BY ORDERS.ORDER_ID
    ORDER BY ORDERS.ORDER_ID),
    URUN_CESIDI_SAYISI AS(SELECT
    ORDERS.ORDER_ID,
    COUNT(PRODUCTS.PRODUCT_ID) AS URUN_CESIDI
    FROM ORDERS
    JOIN ORDER_ITEMS ON ORDER_ITEMS.ORDER_ID=ORDERS.ORDER_ID
    JOIN PRODUCTS ON ORDER_ITEMS.PRODUCT_ID=PRODUCTS.PRODUCT_ID
    GROUP BY ORDERS.ORDER_ID
    ORDER BY ORDERS.ORDER_ID),
    SIPARIS_TUTARI AS (SELECT
    ORDERS.ORDER_ID,
    SUM(ORDER_ITEMS.QUANTITY*ORDER_ITEMS.UNIT_PRICE) AS TUTAR
    FROM ORDER_ITEMS
    JOIN ORDERS ON ORDERS.ORDER_ID=ORDER_ITEMS.ORDER_ID
    GROUP BY ORDERS.ORDER_ID
    ORDER BY ORDERS.ORDER_ID)
SELECT
DISTINCT ORDERS.ORDER_ID AS SIPARISNO,
CUSTOMERS.NAME AS MUSTERIADI,
CONTACTS.FIRST_NAME || ' ' || CONTACTS.LAST_NAME AS KONTAK_ADI,
EMPLOYEES.FIRST_NAME || ' ' || EMPLOYEES.LAST_NAME AS TEMSILCI_ADI,
TOPLAM_URUN_SAYISI.URUN_SAYISI,
URUN_CESIDI_SAYISI.URUN_CESIDI,
ORDERS.STATUS AS SIPARIS_STATUSU,
SIPARIS_TUTARI.TUTAR
FROM CONTACTS
JOIN CUSTOMERS ON CUSTOMERS.CUSTOMER_ID=CONTACTS.CUSTOMER_ID
RIGHT JOIN ORDERS ON ORDERS.CUSTOMER_ID=CUSTOMERS.CUSTOMER_ID
LEFT JOIN ORDER_ITEMS ON ORDER_ITEMS.ORDER_ID=ORDERS.ORDER_ID
JOIN TOPLAM_URUN_SAYISI ON ORDERS.ORDER_ID=TOPLAM_URUN_SAYISI.ORDER_ID
JOIN URUN_CESIDI_SAYISI ON ORDERS.ORDER_ID=URUN_CESIDI_SAYISI.ORDER_ID
JOIN SIPARIS_TUTARI ON ORDERS.ORDER_ID=SIPARIS_TUTARI.ORDER_ID
LEFT JOIN EMPLOYEES ON ORDERS.SALESMAN_ID=EMPLOYEES.EMPLOYEE_ID
JOIN PRODUCTS ON ORDER_ITEMS.PRODUCT_ID=PRODUCTS.PRODUCT_ID
ORDER BY 1


--4--
/*
Stok Bulunurluk Listesi
• Ürün Adý
• Ürün Açýklamasý
• Ürün Kategorisi
• Stok Adet :Tüm Depolarda bulunan toplam adet
• Rezerve adet : Pending durumundaki sipariþlerdeki ürün adeti
• Kullanýlabilir Adet : Stok Adet - Rezerve adet
*/

WITH STOK_ADET AS (SELECT
    PRODUCTS.PRODUCT_ID,
    SUM(INVENTORIES.QUANTITY)AS TOPLAM
    FROM PRODUCTS
    JOIN INVENTORIES ON PRODUCTS.PRODUCT_ID=INVENTORIES.PRODUCT_ID
    GROUP BY PRODUCTS.PRODUCT_ID
    ORDER BY PRODUCTS.PRODUCT_ID),
    REZERVE_ADET AS (SELECT
    PRODUCTS.PRODUCT_ID,
    SUM(ORDER_ITEMS.QUANTITY) AS TOPLAM
    FROM PRODUCTS
    JOIN ORDER_ITEMS ON ORDER_ITEMS.PRODUCT_ID=PRODUCTS.PRODUCT_ID
    JOIN ORDERS ON ORDER_ITEMS.ORDER_ID=ORDERS.ORDER_ID
    WHERE ORDERS.STATUS='Pending'
    GROUP BY PRODUCTS.PRODUCT_ID
    ORDER BY PRODUCTS.PRODUCT_ID)
SELECT
PRODUCTS.PRODUCT_ID,
PRODUCTS.PRODUCT_NAME URUN_ADI,
PRODUCTS.DESCRIPTION AS URUN_ACIKLAMASI,
PRODUCT_CATEGORIES.CATEGORY_NAME KATEGORI_ADI,
COALESCE((STOK_ADET.TOPLAM),0) AS STOK,
COALESCE((REZERVE_ADET.TOPLAM),0) AS REZERVE,
COALESCE((STOK_ADET.TOPLAM),0)-COALESCE((REZERVE_ADET.TOPLAM),0) AS KULLANILABILIR
FROM PRODUCT_CATEGORIES
RIGHT JOIN PRODUCTS ON PRODUCTS.CATEGORY_ID=PRODUCT_CATEGORIES.CATEGORY_ID
LEFT JOIN STOK_ADET ON STOK_ADET.PRODUCT_ID=PRODUCTS.PRODUCT_ID
LEFT JOIN REZERVE_ADET ON STOK_ADET.PRODUCT_ID=REZERVE_ADET.PRODUCT_ID
ORDER BY 1


--5--
/*
Bölge Satýþ Performansý : Her bölgenin her yýlda yaptýðý toplam gerçekleþmiþ Sipariþ Tutarý
• Bölge Adý
• Yýl : *2000-2020 yýllarý sipariþ bulunmasa bile listede görünmelidir.
• Toplam Gerçekleþen Sipariþ Tutarý
• Toplam Ýptal Edilen Sipariþ Tutarý
• Ýptal Yüzdesi
*/

select all_region_yil_comb.region_name,
    all_region_yil_comb.yil,
    coalesce(totals.tutar,0)
  from (select region_name,region_id,yils.yil
          from regions
        cross join (Select 2000+Rownum as yil
            From dual
            Connect By Rownum <= 20 ) yils
            ) all_region_yil_comb
            left outer join(select c.region_id,
            to_char(o.order_date,'YYYY') as yil,
            sum(oi.quantity*oi.unit_price) as tutar
            from countries c
              JOIN locations l ON c.country_id = l.country_id 
              JOIN WAREHOUSES w ON l.location_id = w.location_id 
              JOIN inventories i ON w.warehouse_id = i.warehouse_id 
              JOIN PRODUCTS p ON i.product_id = p.product_id 
              JOIN order_items oi ON p.product_id = oi.product_id 
              JOIN ORDERS o ON oi.order_id = o.order_id 
                group by c.region_id,
                    to_char(o.order_date,'YYYY')) totals
                    on all_region_yil_comb.region_id=totals.region_id
                    and all_region_yil_comb.yil=totals.yil
                order by all_region_yil_comb.region_name, all_region_yil_comb.yil
                
--6--
/*
Müdürlük Seviyesi Yýllýk Satýþ Performansý : Her Sales Manager’ýn ekibinin yaptýðý sipariþ 
toplamýnýn toplam sipariþ tutarýna oraný
• Sales Manager Adý
• Yýl : *2000-2020 yýllarý sipariþ bulunmasa bile listede görünmelidir.
• Hiyerarþide Sales Manager altýnda kalan çalýþanlarýn o yýldaki toplam sipariþ tutar
*/
select
man_year_comb.full_name,
man_year_comb.yil,
nvl(sales.total,0)
from (select
        employee_id,
        first_name||''||last_name as full_name,
        xx.yil
        from employees
        cross join(select
                       2000+rownum as yil
                       from dual
                       connect by rownum<=20) xx
where job_title='Sales Manager') man_year_comb
left outer join(select
                     employees.manager_id,
                     to_char(orders.order_date,'YYYY') as yil,
                     sum(order_items.quantity*order_items.unit_price) as total
                     from orders
                     join order_items on orders.order_id=order_items.order_id
                     join employees on employees.employee_id=orders.salesman_id
                     group by employees.manager_id,to_char(orders.order_date,'YYYY')
) sales on sales.manager_id=man_year_comb.employee_id and sales.yil = man_year_comb.yil
order by 1

--7--
/*
Ürün Performansý : Her ürün için satýlan adetin tüm ürünlerin satýlan adetine oraný 
• Ürün Kategorisi 
• Ürün Adý
• Satýlan Adet 
• Ýptal edilen Adet
• Tüm Satýþlara Göre Yüzdesi
• Tüm Ýptallere Göre Yüzdesi
*/
WITH SATILAN_ADET AS (SELECT
    PRODUCTS.PRODUCT_ID,
    SUM(ORDER_ITEMS.QUANTITY) AS SATILAN
    FROM PRODUCTS
    JOIN ORDER_ITEMS ON ORDER_ITEMS.PRODUCT_ID=PRODUCTS.PRODUCT_ID
    JOIN ORDERS ON ORDERS.ORDER_ID=ORDER_ITEMS.ORDER_ID
    WHERE ORDERS.STATUS='Pending'
    OR ORDERS.STATUS='Shipped'
    GROUP BY PRODUCTS.PRODUCT_ID),
    IPTAL_ADET AS(SELECT
    PRODUCTS.PRODUCT_ID,
    SUM(ORDER_ITEMS.QUANTITY) AS IPTAL
    FROM PRODUCTS
    JOIN ORDER_ITEMS ON ORDER_ITEMS.PRODUCT_ID=PRODUCTS.PRODUCT_ID
    JOIN ORDERS ON ORDERS.ORDER_ID=ORDER_ITEMS.ORDER_ID
    WHERE ORDERS.STATUS='Canceled'
    GROUP BY PRODUCTS.PRODUCT_ID)
SELECT
PRODUCT_CATEGORIES.CATEGORY_NAME AS URUN_KATEGORISI,
PRODUCTS.PRODUCT_NAME AS URUN_ADI,
SATILAN_ADET.SATILAN AS SATILANADET,
IPTAL_ADET.IPTAL AS IPTALADET,
SATILAN_ADET.SATILAN/(SELECT
    SUM(ORDER_ITEMS.QUANTITY) AS SATILAN
    FROM PRODUCTS
    JOIN ORDER_ITEMS ON ORDER_ITEMS.PRODUCT_ID=PRODUCTS.PRODUCT_ID
    JOIN ORDERS ON ORDERS.ORDER_ID=ORDER_ITEMS.ORDER_ID
    WHERE ORDERS.STATUS='Pending'
    OR ORDERS.STATUS='Shipped')*100 AS SATIS_YUZDESI,
IPTAL_ADET.IPTAL/(SELECT
    SUM(ORDER_ITEMS.QUANTITY) AS IPTAL
    FROM PRODUCTS
    JOIN ORDER_ITEMS ON ORDER_ITEMS.PRODUCT_ID=PRODUCTS.PRODUCT_ID
    JOIN ORDERS ON ORDERS.ORDER_ID=ORDER_ITEMS.ORDER_ID
    WHERE ORDERS.STATUS='Canceled')*100 AS IPTAL_YUZDESI    
FROM PRODUCT_CATEGORIES
LEFT JOIN PRODUCTS ON PRODUCTS.CATEGORY_ID=PRODUCT_CATEGORIES.CATEGORY_ID
LEFT JOIN SATILAN_ADET ON SATILAN_ADET.PRODUCT_ID=PRODUCTS.PRODUCT_ID
LEFT JOIN IPTAL_ADET ON IPTAL_ADET.PRODUCT_ID=PRODUCTS.PRODUCT_ID
ORDER BY PRODUCTS.PRODUCT_ID
    

--8--
/*
Depo Stok Karþýlaþtýrma: Her bir ürünün her bir depoda bulunan adetinin tüm depolardaki 
toplam adetine göre yüzdesi.
• Ürün Grubu
• Ürün Adý
• Depo Ülkesi
• Depo Adý
• Mevcut Adet
• Mevcut adetin tüm depolardaki adete göre yüzdesi
*/
SELECT DISTINCT
PRODUCTS.PRODUCT_ID,
 PRODUCT_CATEGORIES.CATEGORY_NAME AS URUN_GRUBU,
PRODUCTS.PRODUCT_NAME AS URUN_ADI,
COUNTRIES.COUNTRY_NAME AS DEPO_ULKESI,
WAREHOUSES.WAREHOUSE_NAME AS DEPO_ADI,
INVENTORIES.QUANTITY AS MEVCUT_ADET,
INVENTORIES.QUANTITY/(SELECT
SUM(INVENTORIES.QUANTITY)
FROM INVENTORIES)*100 AS YUZDELIK
FROM PRODUCT_CATEGORIES
LEFT JOIN PRODUCTS ON PRODUCTS.CATEGORY_ID=PRODUCT_CATEGORIES.CATEGORY_ID
LEFT JOIN INVENTORIES ON INVENTORIES.PRODUCT_ID=PRODUCTS.PRODUCT_ID
LEFT JOIN WAREHOUSES ON WAREHOUSES.WAREHOUSE_ID=INVENTORIES.WAREHOUSE_ID
LEFT JOIN LOCATIONS ON LOCATIONS.LOCATION_ID=WAREHOUSES.LOCATION_ID
LEFT JOIN COUNTRIES ON COUNTRIES.COUNTRY_ID=LOCATIONS.COUNTRY_ID
ORDER BY PRODUCTS.PRODUCT_ID

--9--
/*
Hiyerarþi Listesi: Verilen bir çalýþan adý için çalýþanýn tüm hiyerarþisinin gösterilmesi
• Çalýþan Adý
• Çalýþan Soyadý
• Çalýþan Eposta
• Çalýþan Telefon
*/

SELECT
EMPLOYEE_ID,
MANAGER_ID,
FIRST_NAME AS CALISAN_ADI,
LAST_NAME AS SOYADI, 
EMAIL,
PHONE AS TELEFON,
LEVEL AS HIYERARSI
FROM EMPLOYEES
START WITH EMPLOYEE_ID=1
CONNECT BY MANAGER_ID = PRIOR EMPLOYEE_ID
ORDER BY LEVEL
   

--10--
/*
Görev Tanýmýna Göre Çalýþan Baðlýlýðý: Her bir görev tanýmý ve yýl bazýnda:
• Görev Adý
• Yýl
• Ayrýlan Çalýþan Sayýsý
• Ayrýlan Çalýþan Sayýsýnýn görev tanýmýndaki toplam çalýþana orana (%)
*/
WITH ISTEN_AYRILAN AS (SELECT
    JOB_TITLE,
    COUNT(CASE WHEN EXIT_DATE < '01/01/2017' THEN 1 ELSE NULL END) AS AYRILAN_SAYISI
    FROM EMPLOYEES
    GROUP BY JOB_TITLE
    ORDER BY JOB_TITLE),
    TOPLAM_SAYI AS (SELECT
    JOB_TITLE,
    COUNT(JOB_TITLE) AS TOPLAM
    FROM EMPLOYEES
    GROUP BY JOB_TITLE
    ORDER BY JOB_TITLE)
SELECT
'2016',
TOPLAM_SAYI.JOB_TITLE,
ISTEN_AYRILAN.AYRILAN_SAYISI,
(ISTEN_AYRILAN.AYRILAN_SAYISI/TOPLAM_SAYI.TOPLAM)*100 AS YUZDELIK
FROM TOPLAM_SAYI
FULL JOIN ISTEN_AYRILAN ON ISTEN_AYRILAN.JOB_TITLE=TOPLAM_SAYI.JOB_TITLE

