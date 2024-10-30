WITH recency_temp as (
WITH son_siparis as (
SELECT customerid,
		invoicedate,
		ROW_NUMBER() OVER (PARTITION BY customerid ORDER BY invoicedate DESC) 
FROM rfm_data)
SELECT customerid,
		(SELECT MAX (invoicedate) FROM rfm_data)::date - invoicedate::date gun_degeri
FROM son_siparis
WHERE row_number=1
ORDER BY 2),

frequency_temp as (
SELECT customerid,
		COUNT(DISTINCT invoiceno) sip_sayisi	
FROM rfm_data
GROUP BY 1),

monatary_temp as(
SELECT customerid,
		SUM (unitprice*quantity) top_harcama
FROM rfm_data
GROUP BY 1),

rfm_tablo as (
SELECT * FROM recency_temp
LEFT JOIN frequency_temp USING (customerid)
LEFT JOIN monatary_temp USING (customerid)),

duzenlenmemis_skorlar as (
SELECT *,
		DENSE_RANK() OVER (ORDER BY gun_degeri DESC)as rec,
		DENSE_RANK() OVER (ORDER BY sip_sayisi) as freq,
		DENSE_RANK() OVER (ORDER BY top_harcama) as mon
FROM rfm_tablo),

skor_tablosu as(
SELECT customerid,
		ROUND((rec/ (SELECT MAX (rec) FROM duzenlenmemis_skorlar)::float)*4)+1 rec_skor,
		ROUND((freq/ (SELECT MAX (freq) FROM duzenlenmemis_skorlar)::float)*4)+1 freq_skor,
		ROUND((mon/ (SELECT MAX (mon) FROM duzenlenmemis_skorlar)::float)*4)+1 mon_skor
FROM duzenlenmemis_skorlar)

SELECT 	rec_skor,
		ROUND((freq_skor+mon_skor)/2) as freq_mon_skor,
		COUNT (customerid)
FROM skor_tablosu
GROUP BY 1,2
ORDER BY 1,2
