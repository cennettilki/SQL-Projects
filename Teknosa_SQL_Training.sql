--1--
/*
M��teri �zeti:
� M��teri Ad�
� Adres
� Web Sitesi
� Kredi Limiti
� Toplam Sipari� Tutar�
� Bekleyen Sipari� Tutar�
� �ptal Edilmi� Sipari� Tutar�
*Hi� sipari�i olmayan m��teriler de listede bulunmal�d�r
*/

WITH
	/*Common Table Expression kullanarak sipari� durumuna g�re
	filtreledi�im sat�rlar� farkl� birer tablo gibi kulland�m.*/
    TOPLAM_SIPARIS AS (
    SELECT
    CUSTOMERS.NAME,
    SUM(order_items.quantity*order_items.unit_price) AS TOPLAM
    FROM order_items
    FULL JOIN ORDERS ON ORDERS.order_id=order_items.order_id
    JOIN CUSTOMERS ON CUSTOMERS.customer_id=ORDERS.customer_id
	--Orders ve Customers tablolar�n� JOIN kullanarak birle�tirdim
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
	/*Sorgu sonucunda g�rmek istedi�im sat�rlar� listeledim.*/
SELECT CUSTOMERS.NAME AS MUSTERIADI,
    CUSTOMERS.ADDRESS AS ADRES,
    CUSTOMERS.website AS WEBSITESI,
    CUSTOMERS.credit_limit AS KREDILIMITI,
    TOPLAM_SIPARIS.TOPLAM AS TOPLAM_SIPARIS_TUTARI,
    BEKLEYEN_SIPARIS.BEKLEYEN_TOPLAM AS BEKLEYEN_SIPARIS_TUTARI,
    IPTAL_SIPARIS.IPTAL_TOPLAM AS IPTAL_SIPARIS_TUTARI
FROM customers
	/*Olu�turdu�um common table expressionlar� birle�tirdim.*/
    LEFT JOIN BEKLEYEN_SIPARIS ON BEKLEYEN_SIPARIS.NAME=CUSTOMERS.NAME
    LEFT JOIN IPTAL_SIPARIS ON IPTAL_SIPARIS.NAME=CUSTOMERS.NAME
    LEFT JOIN TOPLAM_SIPARIS ON TOPLAM_SIPARIS.NAME=CUSTOMERS.NAME
ORDER BY 5 DESC-- Sorguyu MUSTERIADI kolonuna g�re s�ralad�m.    


--2--
/*
M��teri Kredi �zeti
� M��teri Ad�
� Kredi Limiti
� Bekleyen Sipari� Tutar�
� Limit A��m�(Evet/Hay�r) : M��terin toplam bekleyen sipari� tutarlar� toplam� Kredi 
limitini a��yorsa Evet, a�m�yorsa Hay�r.
 *Hi� sipari�i olmayan m��teriler de listede bulunmal�d�r
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
    ELSE 'Hay�r'
    END AS DURUM
FROM CUSTOMERS
FULL JOIN BEKLEYEN_SIPARIS_TUTARI ON BEKLEYEN_SIPARIS_TUTARI.NAME=CUSTOMERS.NAME
ORDER BY 1

       

--3--
/*
Sipari� �zeti
� Sipari� No
� M��teri Ad�
� M��teri Kontak Ad�
� Sipari�in Sat�� Temsilcisi Ad�
� Sipari�teki Toplam �r�n Say�s�
� Sipari�teki Toplam �r�n �e�idi Say�s�
� Sipari� Stat�s�
� Sipari� Tutar�
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
� �r�n Ad�
� �r�n A��klamas�
� �r�n Kategorisi
� Stok Adet :T�m Depolarda bulunan toplam adet
� Rezerve adet : Pending durumundaki sipari�lerdeki �r�n adeti
� Kullan�labilir Adet : Stok Adet - Rezerve adet
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
B�lge Sat�� Performans� : Her b�lgenin her y�lda yapt��� toplam ger�ekle�mi� Sipari� Tutar�
� B�lge Ad�
� Y�l : *2000-2020 y�llar� sipari� bulunmasa bile listede g�r�nmelidir.
� Toplam Ger�ekle�en Sipari� Tutar�
� Toplam �ptal Edilen Sipari� Tutar�
� �ptal Y�zdesi
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
M�d�rl�k Seviyesi Y�ll�k Sat�� Performans� : Her Sales Manager��n ekibinin yapt��� sipari� 
toplam�n�n toplam sipari� tutar�na oran�
� Sales Manager Ad�
� Y�l : *2000-2020 y�llar� sipari� bulunmasa bile listede g�r�nmelidir.
� Hiyerar�ide Sales Manager alt�nda kalan �al��anlar�n o y�ldaki toplam sipari� tutar
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
�r�n Performans� : Her �r�n i�in sat�lan adetin t�m �r�nlerin sat�lan adetine oran� 
� �r�n Kategorisi 
� �r�n Ad�
� Sat�lan Adet 
� �ptal edilen Adet
� T�m Sat��lara G�re Y�zdesi
� T�m �ptallere G�re Y�zdesi
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
Depo Stok Kar��la�t�rma: Her bir �r�n�n her bir depoda bulunan adetinin t�m depolardaki 
toplam adetine g�re y�zdesi.
� �r�n Grubu
� �r�n Ad�
� Depo �lkesi
� Depo Ad�
� Mevcut Adet
� Mevcut adetin t�m depolardaki adete g�re y�zdesi
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
Hiyerar�i Listesi: Verilen bir �al��an ad� i�in �al��an�n t�m hiyerar�isinin g�sterilmesi
� �al��an Ad�
� �al��an Soyad�
� �al��an Eposta
� �al��an Telefon
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
G�rev Tan�m�na G�re �al��an Ba�l�l���: Her bir g�rev tan�m� ve y�l baz�nda:
� G�rev Ad�
� Y�l
� Ayr�lan �al��an Say�s�
� Ayr�lan �al��an Say�s�n�n g�rev tan�m�ndaki toplam �al��ana orana (%)
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

